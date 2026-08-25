package com.feixiang.blueapp

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Android 通用经典蓝牙 RFCOMM / SPP（UUID 00001101-...）。
 */
class ClassicSppPlugin(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val METHOD = "com.feixiang.blueapp/spp"
        private const val EVENTS = "com.feixiang.blueapp/spp_events"
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }

    private val methodChannel = MethodChannel(messenger, METHOD)
    private val eventChannel = EventChannel(messenger, EVENTS)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioExecutor = Executors.newCachedThreadPool()

    private var eventSink: EventChannel.EventSink? = null
    private var socket: BluetoothSocket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null
    private val reading = AtomicBoolean(false)
    private var discoveryRegistered = false

    private val discoveryReceiver = object : BroadcastReceiver() {
        @SuppressLint("MissingPermission")
        override fun onReceive(ctx: Context?, intent: Intent?) {
            when (intent?.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                        }
                    if (device == null) return
                    val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE).toInt()
                    emit(
                        mapOf(
                            "type" to "device",
                            "id" to device.address,
                            "name" to (device.name ?: ""),
                            "rssi" to rssi,
                        ),
                    )
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    // no-op; Dart side owns scan timeout
                }
            }
        }
    }

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDiscovery" -> {
                try {
                    startDiscovery()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("startDiscovery", e.message, null)
                }
            }
            "stopDiscovery" -> {
                try {
                    stopDiscovery()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("stopDiscovery", e.message, null)
                }
            }
            "bondedDevices" -> {
                try {
                    result.success(bondedDevices())
                } catch (e: Exception) {
                    result.error("bondedDevices", e.message, null)
                }
            }
            "connect" -> {
                val address = call.argument<String>("address")
                if (address.isNullOrBlank()) {
                    result.error("connect", "address required", null)
                    return
                }
                ioExecutor.execute {
                    try {
                        connect(address)
                        mainHandler.post { result.success(null) }
                    } catch (e: Exception) {
                        emit(mapOf("type" to "error", "message" to (e.message ?: "connect failed")))
                        mainHandler.post { result.error("connect", e.message, null) }
                    }
                }
            }
            "disconnect" -> {
                ioExecutor.execute {
                    try {
                        disconnectInternal()
                        mainHandler.post { result.success(null) }
                    } catch (e: Exception) {
                        mainHandler.post { result.error("disconnect", e.message, null) }
                    }
                }
            }
            "write" -> {
                val data = call.argument<ByteArray>("data")
                if (data == null) {
                    result.error("write", "data required", null)
                    return
                }
                ioExecutor.execute {
                    try {
                        write(data)
                        mainHandler.post { result.success(null) }
                    } catch (e: Exception) {
                        emit(mapOf("type" to "error", "message" to (e.message ?: "write failed")))
                        mainHandler.post { result.error("write", e.message, null) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    @SuppressLint("MissingPermission")
    private fun startDiscovery() {
        ensureBluetoothPermissions()
        val adapter = adapterOrThrow()
        registerDiscoveryReceiver()
        if (adapter.isDiscovering) {
            adapter.cancelDiscovery()
        }
        if (!adapter.startDiscovery()) {
            throw IllegalStateException("startDiscovery failed")
        }
    }

    @SuppressLint("MissingPermission")
    private fun stopDiscovery() {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter?.isDiscovering == true) {
            adapter.cancelDiscovery()
        }
        unregisterDiscoveryReceiver()
    }

    @SuppressLint("MissingPermission")
    private fun bondedDevices(): List<Map<String, Any?>> {
        ensureBluetoothPermissions()
        val adapter = adapterOrThrow()
        return adapter.bondedDevices?.map { device ->
            mapOf(
                "id" to device.address,
                "name" to (device.name ?: ""),
                "rssi" to -60,
            )
        } ?: emptyList()
    }

    @SuppressLint("MissingPermission")
    private fun connect(address: String) {
        ensureBluetoothPermissions()
        val adapter = adapterOrThrow()
        if (adapter.isDiscovering) {
            adapter.cancelDiscovery()
        }
        disconnectInternal()
        val device = adapter.getRemoteDevice(address)
        val sock = device.createRfcommSocketToServiceRecord(SPP_UUID)
        sock.connect()
        socket = sock
        inputStream = sock.inputStream
        outputStream = sock.outputStream
        emit(mapOf("type" to "connected", "id" to address))
        startReadLoop()
    }

    private fun write(data: ByteArray) {
        val out = outputStream ?: throw IllegalStateException("not connected")
        out.write(data)
        out.flush()
    }

    private fun disconnectInternal() {
        reading.set(false)
        try {
            inputStream?.close()
        } catch (_: Exception) {
        }
        try {
            outputStream?.close()
        } catch (_: Exception) {
        }
        try {
            socket?.close()
        } catch (_: Exception) {
        }
        inputStream = null
        outputStream = null
        val wasOpen = socket != null
        socket = null
        if (wasOpen) {
            emit(mapOf("type" to "disconnected"))
        }
    }

    private fun startReadLoop() {
        reading.set(true)
        val input = inputStream ?: return
        ioExecutor.execute {
            val buf = ByteArray(1024)
            while (reading.get()) {
                try {
                    val n = input.read(buf)
                    if (n < 0) {
                        break
                    }
                    if (n > 0) {
                        val chunk = buf.copyOf(n)
                        emit(mapOf("type" to "data", "data" to chunk))
                    }
                } catch (_: IOException) {
                    break
                }
            }
            if (reading.get()) {
                reading.set(false)
                emit(mapOf("type" to "disconnected"))
                try {
                    socket?.close()
                } catch (_: Exception) {
                }
                socket = null
                inputStream = null
                outputStream = null
            }
        }
    }

    private fun registerDiscoveryReceiver() {
        if (discoveryRegistered) return
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(discoveryReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(discoveryReceiver, filter)
        }
        discoveryRegistered = true
    }

    private fun unregisterDiscoveryReceiver() {
        if (!discoveryRegistered) return
        try {
            context.unregisterReceiver(discoveryReceiver)
        } catch (_: Exception) {
        }
        discoveryRegistered = false
    }

    private fun adapterOrThrow(): BluetoothAdapter {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = manager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
        return adapter ?: throw IllegalStateException("BluetoothAdapter unavailable")
    }

    private fun ensureBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val connect = ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT)
            val scan = ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN)
            if (connect != PackageManager.PERMISSION_GRANTED || scan != PackageManager.PERMISSION_GRANTED) {
                throw SecurityException("BLUETOOTH_CONNECT/SCAN not granted")
            }
        }
    }

    private fun emit(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    fun dispose() {
        stopDiscovery()
        disconnectInternal()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        ioExecutor.shutdownNow()
    }
}
