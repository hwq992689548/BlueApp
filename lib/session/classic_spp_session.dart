import 'dart:async';
import 'dart:typed_data';

import 'package:blue_app/core/app_log.dart';
import 'package:blue_app/core/feasy_platform.dart';
import 'package:blue_app/core/hex_support.dart';
import 'package:blue_app/core/log_entry.dart';
import 'package:blue_app/core/log_store.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/spp/classic_spp_channel.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';

/// Android 系统 RFCOMM / 经典蓝牙 SPP 会话。
class ClassicSppSession implements LinkSession {
  ClassicSppSession({ClassicSppChannel? channel}) : _channel = channel ?? ClassicSppChannel() {
    AppLog.info('[会话] ClassicSpp 创建');
    _eventsSub = _channel.observe().listen(_onEvent, onError: (Object e, StackTrace st) {
      AppLog.error('[SPP] events 错误 $e\n$st');
      _appendInfo('SPP 事件错误: $e');
    });
  }

  final ClassicSppChannel _channel;
  final _store = LogStore();

  final _scanResults$ = BehaviorSubject<List<ScanItem>>.seeded(const []);
  final _isScanning$ = BehaviorSubject<bool>.seeded(false);
  final _isConnected$ = BehaviorSubject<bool>.seeded(false);
  final _logs$ = BehaviorSubject<List<LogEntry>>.seeded(const []);

  final Map<String, ScanItem> _devices = {};
  StreamSubscription<Map<dynamic, dynamic>>? _eventsSub;
  Completer<void>? _connectCompleter;
  Timer? _scanTimer;
  bool _disposed = false;

  @override
  bool get hasGattTree => false;

  @override
  ScanKind get scanKind => ScanKind.classic;

  @override
  Stream<List<ScanItem>> get scanResults$ => _scanResults$;

  @override
  Stream<bool> get isScanning$ => _isScanning$;

  @override
  Stream<bool> get isConnected$ => _isConnected$;

  @override
  Stream<List<LogEntry>> get logs$ => _logs$;

  @override
  ScanItem? connectedItem;

  @override
  Future<bool> isBluetoothOn() async {
    try {
      final state = await FlutterBluePlus.adapterState
          .firstWhere((s) => s != BluetoothAdapterState.unknown)
          .timeout(const Duration(milliseconds: 200));
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
    }
  }

  @override
  Future<void> turnOnBluetooth() async {
    await FlutterBluePlus.turnOn();
  }

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    _ensureNotDisposed();
    _ensureAndroid();
    AppLog.info('[扫描] ClassicSpp start timeout=${timeout.inSeconds}s');
    await _channel.requestPermissions();
    await stopScan();
    _devices.clear();
    _scanResults$.add(const []);
    _isScanning$.add(true);
    _appendInfo('开始经典蓝牙扫描');

    try {
      final bonded = await _channel.bondedDevices();
      for (final raw in bonded) {
        _upsertDevice(raw, bondedFallbackRssi: -60);
      }
      _publishScan();
      await _channel.startDiscovery();
    } catch (e, st) {
      AppLog.error('[扫描] startDiscovery 失败 $e\n$st');
      _appendInfo('扫描失败: $e');
      _isScanning$.add(false);
      rethrow;
    }

    _scanTimer?.cancel();
    _scanTimer = Timer(timeout, () {
      unawaited(stopScan());
    });
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    try {
      if (FeasyPlatform.classicSupported) {
        await _channel.stopDiscovery();
      }
    } catch (e) {
      AppLog.warning('[扫描] stopDiscovery $e');
    }
    if (!_disposed) {
      _isScanning$.add(false);
    }
  }

  @override
  Future<void> connect(ScanItem item, {Duration timeout = const Duration(seconds: 15)}) async {
    _ensureNotDisposed();
    _ensureAndroid();
    AppLog.info('[连接] ClassicSpp id=${item.id} name=${item.name}');
    await stopScan();
    await disconnect();
    connectedItem = item;
    _appendInfo('连接 ${item.id}');

    final completer = Completer<void>();
    _connectCompleter = completer;
    try {
      // Timeout covers MethodChannel connect + waiting for native `connected`.
      await Future<void>(() async {
        await _channel.connect(item.id);
        await completer.future;
      }).timeout(timeout);
      if (!_disposed) {
        _isConnected$.add(true);
        AppLog.success('[连接] ClassicSpp 已连接 ${item.id}');
        _appendInfo('已连接 ${item.id}');
      }
    } catch (e, st) {
      AppLog.error('[连接] ClassicSpp 失败 $e\n$st');
      try {
        await disconnect();
      } catch (_) {}
      rethrow;
    } finally {
      if (identical(_connectCompleter, completer)) {
        _connectCompleter = null;
      }
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      if (FeasyPlatform.classicSupported) {
        await _channel.disconnect();
      }
    } catch (e) {
      AppLog.warning('[连接] disconnect $e');
      _appendInfo('disconnect: $e');
    }
    if (!_disposed) {
      connectedItem = null;
      _isConnected$.add(false);
    }
  }

  @override
  Future<void> send(List<int> bytes) async {
    _ensureNotDisposed();
    final data = Uint8List.fromList(bytes);
    AppLog.info('[SPP] TX len=${data.length} hex=${HexSupport.bytesToHex(data)}');
    await _channel.write(data);
    _logBytes(direction: LogDirection.tx, bytes: data, message: 'SPP TX');
  }

  @override
  void clearLogs() {
    if (!_disposed) {
      _store.clear();
      _pushLogs();
    }
  }

  @override
  Future<void> prepare() async {}

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await stopScan();
    await _eventsSub?.cancel();
    _eventsSub = null;
    try {
      await _channel.disconnect();
    } catch (_) {}
    await _scanResults$.close();
    await _isScanning$.close();
    await _isConnected$.close();
    await _logs$.close();
  }

  void _onEvent(Map<dynamic, dynamic> event) {
    if (_disposed) {
      return;
    }
    final type = event['type']?.toString();
    switch (type) {
      case 'device':
        _upsertDevice(event);
        _publishScan();
      case 'connected':
        if (!_disposed) {
          _isConnected$.add(true);
        }
        final c = _connectCompleter;
        if (c != null && !c.isCompleted) {
          c.complete();
        }
      case 'disconnected':
        if (!_disposed) {
          connectedItem = null;
          _isConnected$.add(false);
        }
        _appendInfo('已断开');
      case 'data':
        final raw = event['data'];
        final bytes = raw is Uint8List
            ? raw
            : raw is List
                ? Uint8List.fromList(raw.cast<int>())
                : Uint8List(0);
        if (bytes.isNotEmpty) {
          AppLog.info('[SPP] RX len=${bytes.length} hex=${HexSupport.bytesToHex(bytes)}');
          _logBytes(direction: LogDirection.rx, bytes: bytes, message: 'SPP RX');
        }
      case 'error':
        final message = event['message']?.toString() ?? 'unknown';
        AppLog.error('[SPP] error $message');
        _appendInfo('SPP 错误: $message');
        final c = _connectCompleter;
        if (c != null && !c.isCompleted) {
          c.completeError(StateError(message));
        }
      default:
        AppLog.warning('[SPP] 未知事件 type=$type');
    }
  }

  void _upsertDevice(Map<dynamic, dynamic> raw, {int bondedFallbackRssi = -100}) {
    final id = raw['id']?.toString() ?? raw['address']?.toString() ?? '';
    if (id.isEmpty) {
      return;
    }
    final name = raw['name']?.toString() ?? '';
    final rssiRaw = raw['rssi'];
    final rssi = rssiRaw is int ? rssiRaw : bondedFallbackRssi;
    _devices[id] = ScanItem(
      id: id,
      name: name,
      rssi: rssi,
      kind: ScanKind.classic,
      connectable: true,
    );
  }

  void _publishScan() {
    if (_disposed) {
      return;
    }
    final list = _devices.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
    _scanResults$.add(list);
  }

  void _ensureAndroid() {
    if (!FeasyPlatform.classicSupported) {
      throw UnsupportedError('经典蓝牙仅 Android');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('ClassicSppSession disposed');
    }
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
}
