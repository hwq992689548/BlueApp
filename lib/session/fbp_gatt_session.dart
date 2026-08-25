import 'dart:async';

import 'package:blue_app/core/app_log.dart';
import 'package:blue_app/core/hex_support.dart';
import 'package:blue_app/core/log_entry.dart';
import 'package:blue_app/core/log_store.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';

/// flutter_blue_plus GATT 会话：扫描 / 单连接 / 服务树 / 日志。
class FbpGattSession implements LinkSession {
  FbpGattSession() {
    AppLog.info('[会话] 创建');
  }

  @override
  bool get hasGattTree => true;

  @override
  ScanKind get scanKind => ScanKind.ble;

  final _scanResults$ = BehaviorSubject<List<ScanItem>>.seeded(const []);
  final _isScanning$ = BehaviorSubject<bool>.seeded(false);
  final _isConnected$ = BehaviorSubject<bool>.seeded(false);
  final _logs$ = BehaviorSubject<List<LogEntry>>.seeded(const []);
  final _device$ = BehaviorSubject<BluetoothDevice?>.seeded(null);
  final _services$ = BehaviorSubject<List<BluetoothService>>.seeded(const []);
  final _rssi$ = BehaviorSubject<int?>.seeded(null);
  final _mtu$ = BehaviorSubject<int?>.seeded(null);

  final _store = LogStore();

  @override
  Stream<List<ScanItem>> get scanResults$ => _scanResults$;
  @override
  Stream<bool> get isScanning$ => _isScanning$;
  @override
  Stream<bool> get isConnected$ => _isConnected$;
  @override
  Stream<List<LogEntry>> get logs$ => _logs$;

  Stream<List<BluetoothService>> get services$ => _services$;
  Stream<int?> get rssi$ => _rssi$;
  Stream<int?> get mtu$ => _mtu$;

  @override
  ScanItem? connectedItem;

  StreamSubscription<List<ScanResult>>? _scanResultsSub;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  StreamSubscription<int>? _mtuSub;
  Timer? _rssiTimer;
  final Map<String, StreamSubscription<List<int>>> _notifySubs = {};
  int _lastScanCountLogged = -1;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  Future<bool> isBluetoothOn() async {
    try {
      final state = await FlutterBluePlus.adapterState
          .firstWhere((s) => s != BluetoothAdapterState.unknown)
          .timeout(const Duration(milliseconds: 200));
      AppLog.info('[适配器] state=$state');
      return state == BluetoothAdapterState.on;
    } catch (e) {
      final now = FlutterBluePlus.adapterStateNow;
      AppLog.warning('[适配器] 读取超时 fallback=$now err=$e');
      return now == BluetoothAdapterState.on;
    }
  }

  @override
  Future<void> turnOnBluetooth() async {
    AppLog.info('[适配器] turnOn');
    await FlutterBluePlus.turnOn();
  }

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    _ensureNotDisposed();
    AppLog.info('[扫描] start timeout=${timeout.inSeconds}s');
    await stopScan();
    await _scanResultsSub?.cancel();
    _lastScanCountLogged = -1;
    _scanResults$.add(const []);
    _scanResultsSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (_disposed) {
          return;
        }
        final merged = <String, ScanResult>{};
        for (final result in results) {
          merged[result.device.remoteId.str] = result;
        }
        final list = merged.values
            .map(
              (result) => ScanItem(
                id: result.device.remoteId.str,
                name: result.advertisementData.advName.isNotEmpty
                    ? result.advertisementData.advName
                    : result.device.platformName,
                rssi: result.rssi,
                kind: ScanKind.ble,
                connectable: result.advertisementData.connectable,
              ),
            )
            .toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
        _scanResults$.add(list);
        if (list.length != _lastScanCountLogged) {
          _lastScanCountLogged = list.length;
          AppLog.info('[扫描] 结果数=${list.length}');
        }
      },
      onError: (Object e, StackTrace st) {
        AppLog.error('[扫描] onScanResults 错误 $e\n$st');
        _appendInfo('扫描错误: $e');
      },
    );
    _isScanning$.add(true);
    _appendInfo('开始扫描');
    try {
      await FlutterBluePlus.startScan(timeout: timeout, androidUsesFineLocation: true);
      AppLog.success('[扫描] startScan 调用完成（含超时等待）');
    } catch (e, st) {
      AppLog.error('[扫描] startScan 失败 $e\n$st');
      _appendInfo('startScan 失败: $e');
      _isScanning$.add(false);
      rethrow;
    } finally {
      if (!_disposed && !FlutterBluePlus.isScanningNow) {
        _isScanning$.add(false);
        AppLog.info('[扫描] isScanning=false');
      }
    }
  }

  @override
  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      AppLog.info('[扫描] stopScan');
      await FlutterBluePlus.stopScan();
    }
    if (!_disposed) {
      _isScanning$.add(false);
    }
  }

  @override
  Future<void> connect(ScanItem item, {Duration timeout = const Duration(seconds: 15)}) async {
    _ensureNotDisposed();
    final device = BluetoothDevice.fromId(item.id);
    final id = item.id;
    final name = item.name;
    AppLog.info('[连接] 开始 id=$id name=$name timeout=${timeout.inSeconds}s');
    await stopScan();
    await disconnect();
    _appendInfo('连接 $id');
    connectedItem = item;
    _device$.add(device);
    await _connectionStateSub?.cancel();
    _connectionStateSub = device.connectionState.listen((state) {
      if (_disposed) {
        return;
      }
      AppLog.info('[连接] connectionState=$state id=$id');
      _isConnected$.add(state == BluetoothConnectionState.connected);
      if (state == BluetoothConnectionState.disconnected) {
        _stopRssiPolling();
        _services$.add(const []);
      }
    });
    await _mtuSub?.cancel();
    _mtuSub = device.mtu.listen((value) {
      if (!_disposed) {
        _mtu$.add(value);
        AppLog.info('[MTU] stream=$value');
      }
    });
    try {
      await device.connect(license: License.nonprofit, timeout: timeout, autoConnect: false);
      AppLog.success('[连接] connect 成功 id=$id');
    } catch (e, st) {
      AppLog.error('[连接] connect 失败 id=$id $e\n$st');
      rethrow;
    }
    AppLog.info('[服务] discoverServices…');
    final services = await device.discoverServices();
    if (_disposed) {
      return;
    }
    var charCount = 0;
    for (final service in services) {
      charCount += service.characteristics.length;
      AppLog.info('[服务] ${service.uuid.str} chars=${service.characteristics.length}');
    }
    _services$.add(services);
    _mtu$.add(device.mtuNow);
    _startRssiPolling(device);
    AppLog.success('[服务] 发现完成 services=${services.length} characteristics=$charCount mtu=${device.mtuNow}');
    _appendInfo('已连接 · ${services.length} services · $charCount chars');
  }

  @override
  Future<void> disconnect() async {
    final device = _device$.valueOrNull;
    final id = device?.remoteId.str;
    if (device != null) {
      AppLog.info('[连接] disconnect id=$id');
    }
    await _cancelAllNotifies();
    _stopRssiPolling();
    await _mtuSub?.cancel();
    _mtuSub = null;
    await _connectionStateSub?.cancel();
    _connectionStateSub = null;
    if (device != null) {
      try {
        await device.disconnect();
        AppLog.success('[连接] 已断开 id=$id');
      } catch (e, st) {
        AppLog.error('[连接] disconnect 异常 $e\n$st');
        _appendInfo('disconnect: $e');
      }
    }
    if (!_disposed) {
      connectedItem = null;
      _device$.add(null);
      _isConnected$.add(false);
      _services$.add(const []);
      _rssi$.add(null);
      _mtu$.add(null);
    }
  }

  @override
  Future<void> send(List<int> bytes) async {
    throw StateError('GATT 必须写特征');
  }

  Future<void> requestMtu(int mtu) async {
    final device = _device$.valueOrNull;
    if (device == null) {
      AppLog.warning('[MTU] 未连接');
      _appendInfo('未连接，无法 requestMtu');
      return;
    }
    AppLog.info('[MTU] requestMtu=$mtu');
    try {
      final next = await device.requestMtu(mtu);
      _mtu$.add(next);
      AppLog.success('[MTU] → $next');
      _appendInfo('MTU → $next');
    } catch (e, st) {
      AppLog.error('[MTU] 失败 $e\n$st');
      _appendInfo('requestMtu 失败: $e');
    }
  }

  Future<List<int>> readCharacteristic(BluetoothCharacteristic characteristic) async {
    AppLog.info('[GATT] READ ${characteristic.serviceUuid.str}/${characteristic.uuid.str}');
    try {
      final value = await characteristic.read();
      AppLog.success('[GATT] READ ok len=${value.length} hex=${HexSupport.bytesToHex(value)}');
      _logBytes(direction: LogDirection.rx, bytes: value, message: 'READ ${characteristic.uuid.str}');
      return value;
    } catch (e, st) {
      AppLog.error('[GATT] READ 失败 $e\n$st');
      rethrow;
    }
  }

  Future<void> writeCharacteristic(
    BluetoothCharacteristic characteristic,
    List<int> bytes, {
    required bool withoutResponse,
  }) async {
    AppLog.info(
      '[GATT] WRITE withoutResponse=$withoutResponse '
      '${characteristic.serviceUuid.str}/${characteristic.uuid.str} '
      'len=${bytes.length} hex=${HexSupport.bytesToHex(bytes)}',
    );
    try {
      await characteristic.write(bytes, withoutResponse: withoutResponse);
      AppLog.success('[GATT] WRITE ok');
      _logBytes(direction: LogDirection.tx, bytes: bytes, message: 'WRITE ${characteristic.uuid.str}');
    } catch (e, st) {
      AppLog.error('[GATT] WRITE 失败 $e\n$st');
      rethrow;
    }
  }

  Future<void> setNotify(BluetoothCharacteristic characteristic, bool enabled) async {
    final key = _characteristicKey(characteristic);
    AppLog.info('[GATT] Notify ${enabled ? 'ON' : 'OFF'} ${characteristic.serviceUuid.str}/${characteristic.uuid.str}');
    if (!enabled) {
      final sub = _notifySubs.remove(key);
      await sub?.cancel();
      await characteristic.setNotifyValue(false);
      _appendInfo('Notify OFF ${characteristic.uuid.str}');
      return;
    }
    await characteristic.setNotifyValue(true);
    await _notifySubs[key]?.cancel();
    _notifySubs[key] = characteristic.onValueReceived.listen((value) {
      AppLog.info('[GATT] NOTIFY ${characteristic.uuid.str} len=${value.length} hex=${HexSupport.bytesToHex(value)}');
      _logBytes(direction: LogDirection.rx, bytes: value, message: 'NOTIFY ${characteristic.uuid.str}');
    });
    _appendInfo('Notify ON ${characteristic.uuid.str}');
  }

  @override
  void clearLogs() {
    AppLog.info('[日志] clear');
    if (!_disposed) {
      _store.clear();
      _pushLogs();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    AppLog.info('[会话] dispose');
    _disposed = true;
    await stopScan();
    await _cancelAllNotifies();
    _stopRssiPolling();
    await _scanResultsSub?.cancel();
    await _mtuSub?.cancel();
    await _connectionStateSub?.cancel();
    final device = _device$.valueOrNull;
    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        AppLog.warning('[会话] dispose disconnect $e');
      }
    }
    await _scanResults$.close();
    await _isScanning$.close();
    await _isConnected$.close();
    await _device$.close();
    await _services$.close();
    await _rssi$.close();
    await _mtu$.close();
    await _logs$.close();
  }

  void _appendInfo(String message) {
    if (_disposed) {
      return;
    }
    _store.appendInfo(message);
    _pushLogs();
  }

  void _logBytes({required LogDirection direction, required List<int> bytes, String? message}) {
    if (_disposed) {
      return;
    }
    _store.appendBytes(direction: direction, bytes: bytes, message: message);
    _pushLogs();
  }

  void _pushLogs() {
    if (!_disposed) {
      _logs$.add(_store.entries);
    }
  }

  String _characteristicKey(BluetoothCharacteristic characteristic) {
    return '${characteristic.remoteId.str}|${characteristic.serviceUuid}|${characteristic.uuid}';
  }

  Future<void> _cancelAllNotifies() async {
    final subs = Map<String, StreamSubscription<List<int>>>.from(_notifySubs);
    _notifySubs.clear();
    for (final sub in subs.values) {
      await sub.cancel();
    }
  }

  void _startRssiPolling(BluetoothDevice device) {
    _stopRssiPolling();
    _rssiTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_disposed) {
        return;
      }
      try {
        final rssi = await device.readRssi();
        if (!_disposed) {
          _rssi$.add(rssi);
        }
      } catch (e) {
        AppLog.warning('[RSSI] readRssi $e');
      }
    });
  }

  void _stopRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('FbpGattSession disposed');
    }
  }
}
