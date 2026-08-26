import 'dart:async';

import 'package:blue_app/core/app_log.dart';
import 'package:blue_app/core/feasy_platform.dart';
import 'package:blue_app/core/hex_support.dart';
import 'package:blue_app/core/log_entry.dart';
import 'package:blue_app/core/log_store.dart';
import 'package:blue_app/session/feasy_scan_mapper.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/session/scan_accumulator.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:feasy_blue_sdk/feasy_blue_sdk.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

/// Feasy 纯字节通道：Android SPP / iOS FACP，无 GATT 树、无 LP 协议。
class FeasyLinkSession implements LinkSession {
  FeasyLinkSession({FeasyBlueSdk? sdk}) : _sdk = sdk ?? FeasyBlueSdk.instance {
    AppLog.info('[会话] FeasyLink 创建');
    _scanSub = _sdk.scanDevice$.listen(_onScanDevice, onError: (Object e, StackTrace st) {
      AppLog.error('[Feasy] scanDevice 错误 $e\n$st');
      _appendInfo('扫描事件错误: $e');
    });
    _connectionSub = _sdk.connectionState$.listen(_onConnectionState, onError: (Object e, StackTrace st) {
      AppLog.error('[Feasy] connectionState 错误 $e\n$st');
      _appendInfo('连接状态错误: $e');
    });
    _packetSub = _sdk.packetReceived$.listen(_onPacket, onError: (Object e, StackTrace st) {
      AppLog.error('[Feasy] packetReceived 错误 $e\n$st');
      _appendInfo('收包错误: $e');
    });
  }

  final FeasyBlueSdk _sdk;
  final _store = LogStore();

  final _scanResults$ = BehaviorSubject<List<ScanItem>>.seeded(const []);
  final _isScanning$ = BehaviorSubject<bool>.seeded(false);
  final _isConnected$ = BehaviorSubject<bool>.seeded(false);
  final _logs$ = BehaviorSubject<List<LogEntry>>.seeded(const []);

  final _accumulator = ScanAccumulator();
  StreamSubscription<FeasyBlueScanDevice>? _scanSub;
  StreamSubscription<FeasyBlueConnectionStateEvent>? _connectionSub;
  StreamSubscription<FeasyBluePacketReceivedEvent>? _packetSub;
  Completer<void>? _connectCompleter;
  String? _connectingAddress;
  Timer? _scanTimer;
  bool _initialized = false;
  bool _disposed = false;

  @override
  bool get hasGattTree => false;

  @override
  ScanKind get scanKind => ScanKind.feasy;

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

  /// UI 开 Feasy 开关时调用；失败向上抛，由 UI 弹回开关。
  Future<void> initialize() async {
    _ensureNotDisposed();
    _ensureSupported();
    if (_initialized) {
      return;
    }
    AppLog.info('[Feasy] initialize useSppOnAndroid=true');
    await _sdk.initialize(useSppOnAndroid: true);
    _initialized = true;
    AppLog.success('[Feasy] initialize 完成');
  }

  @override
  Future<void> prepare() => initialize();

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
    _ensureSupported();
    AppLog.info('[扫描] Feasy start timeout=${timeout.inSeconds}s');
    await initialize();
    await stopScan();
    _accumulator.clear();
    _scanResults$.add(const []);
    _isScanning$.add(true);
    _appendInfo('开始 Feasy 扫描');

    try {
      await _sdk.startScan();
    } catch (e, st) {
      AppLog.error('[扫描] Feasy startScan 失败 $e\n$st');
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
      if (FeasyPlatform.isSupported && _initialized) {
        await _sdk.stopScan();
      }
    } catch (e) {
      AppLog.warning('[扫描] Feasy stopScan $e');
    }
    if (!_disposed) {
      _isScanning$.add(false);
    }
  }

  @override
  void clearScanResults() {
    _accumulator.clear();
    if (!_disposed) {
      _scanResults$.add(const []);
    }
  }

  @override
  Future<void> connect(ScanItem item, {Duration timeout = const Duration(seconds: 15)}) async {
    _ensureNotDisposed();
    _ensureSupported();
    AppLog.info('[连接] Feasy id=${item.id} name=${item.name}');
    await initialize();
    await stopScan();
    await disconnect();
    connectedItem = item;
    _connectingAddress = item.id;
    _appendInfo('连接 ${item.id}');

    final completer = Completer<void>();
    _connectCompleter = completer;
    try {
      await Future<void>(() async {
        await _sdk.connect(
          address: item.id,
          name: item.name,
          timeout: timeout,
          facpType: FeasyBlueFacpType.v2_1,
        );
        await completer.future;
      }).timeout(timeout);
      if (!_disposed) {
        _isConnected$.add(true);
        AppLog.success('[连接] Feasy 已连接 ${item.id}');
        _appendInfo('已连接 ${item.id}');
      }
    } catch (e, st) {
      AppLog.error('[连接] Feasy 失败 $e\n$st');
      try {
        await disconnect();
      } catch (_) {}
      rethrow;
    } finally {
      if (identical(_connectCompleter, completer)) {
        _connectCompleter = null;
      }
      _connectingAddress = null;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      if (FeasyPlatform.isSupported && _initialized) {
        await _sdk.disconnect(address: connectedItem?.id);
      }
    } catch (e) {
      AppLog.warning('[连接] Feasy disconnect $e');
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
    final id = connectedItem?.id;
    if (id == null) {
      throw StateError('FeasyLinkSession 未连接');
    }
    final data = Uint8List.fromList(bytes);
    AppLog.info('[Feasy] TX len=${data.length} hex=${HexSupport.bytesToHex(data)}');
    await _sdk.send(address: id, data: data, withResponse: false);
    _logBytes(direction: LogDirection.tx, bytes: data, message: 'Feasy TX');
  }

  @override
  void clearLogs() {
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
    _disposed = true;
    await stopScan();
    await _scanSub?.cancel();
    await _connectionSub?.cancel();
    await _packetSub?.cancel();
    _scanSub = null;
    _connectionSub = null;
    _packetSub = null;
    try {
      if (FeasyPlatform.isSupported && _initialized) {
        await _sdk.disconnect(address: connectedItem?.id);
      }
    } catch (_) {}
    await _scanResults$.close();
    await _isScanning$.close();
    await _isConnected$.close();
    await _logs$.close();
  }

  void _onScanDevice(FeasyBlueScanDevice device) {
    if (_disposed) {
      return;
    }
    final item = feasyScanToItem(device);
    if (item.id.isEmpty) {
      return;
    }
    _accumulator.upsert(item);
    _publishScan();
  }

  @visibleForTesting
  void debugEmitConnectionState(FeasyBlueConnectionStateEvent event) {
    _onConnectionState(event);
  }

  bool _isOurAddress(String address) {
    final expected = _connectingAddress ?? connectedItem?.id;
    return expected != null && expected == address;
  }

  void _onConnectionState(FeasyBlueConnectionStateEvent event) {
    if (_disposed) {
      return;
    }
    if (!_isOurAddress(event.address)) {
      return;
    }
    switch (event.state) {
      case FeasyBlueConnectionState.connected:
        if (!_disposed) {
          _isConnected$.add(true);
        }
        final c = _connectCompleter;
        if (c != null && !c.isCompleted) {
          c.complete();
        }
      case FeasyBlueConnectionState.failed:
        final c = _connectCompleter;
        if (c != null && !c.isCompleted) {
          c.completeError(StateError('Feasy 连接失败 ${event.address}'));
        }
        if (!_disposed) {
          connectedItem = null;
          _isConnected$.add(false);
        }
        _appendInfo('连接失败 ${event.address}');
      case FeasyBlueConnectionState.disconnected:
        if (!_disposed) {
          connectedItem = null;
          _isConnected$.add(false);
        }
        _appendInfo('已断开');
      case FeasyBlueConnectionState.connecting:
        break;
    }
  }

  void _onPacket(FeasyBluePacketReceivedEvent event) {
    if (_disposed) {
      return;
    }
    final connectedId = connectedItem?.id;
    if (connectedId != null && event.address != connectedId) {
      return;
    }
    final bytes = event.data;
    if (bytes.isEmpty) {
      return;
    }
    AppLog.info('[Feasy] RX len=${bytes.length} hex=${HexSupport.bytesToHex(bytes)}');
    _logBytes(direction: LogDirection.rx, bytes: bytes, message: 'Feasy RX');
  }

  void _publishScan() {
    if (_disposed) {
      return;
    }
    final list = _accumulator.snapshot();
    _scanResults$.add(list);
  }

  void _ensureSupported() {
    if (!FeasyPlatform.isSupported) {
      throw UnsupportedError('Feasy 仅 Android/iOS');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('FeasyLinkSession disposed');
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
