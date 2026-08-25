import 'package:blue_app/core/log_entry.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:rxdart/rxdart.dart';

class FakeLinkSession implements LinkSession {
  FakeLinkSession({required this.scanKind});

  @override
  final ScanKind scanKind;
  @override
  bool get hasGattTree => scanKind == ScanKind.ble;
  @override
  ScanItem? connectedItem;

  int stopScanCount = 0;
  int disconnectCount = 0;
  int disposeCount = 0;
  int connectCount = 0;
  ScanItem? lastConnected;
  Object? connectError;
  bool bluetoothOn = true;

  final _scanResults$ = BehaviorSubject<List<ScanItem>>.seeded(const []);
  final _isScanning$ = BehaviorSubject<bool>.seeded(false);
  final _isConnected$ = BehaviorSubject<bool>.seeded(false);
  final _logs$ = BehaviorSubject<List<LogEntry>>.seeded(const []);

  void emitScanResults(List<ScanItem> items) => _scanResults$.add(items);
  void emitLogs(List<LogEntry> logs) => _logs$.add(logs);
  void emitScanning(bool value) => _isScanning$.add(value);

  @override
  Stream<List<ScanItem>> get scanResults$ => _scanResults$;
  @override
  Stream<bool> get isScanning$ => _isScanning$;
  @override
  Stream<bool> get isConnected$ => _isConnected$;
  @override
  Stream<List<LogEntry>> get logs$ => _logs$;

  @override
  Future<bool> isBluetoothOn() async => bluetoothOn;
  @override
  Future<void> turnOnBluetooth() async {}
  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {}
  @override
  Future<void> stopScan() async => stopScanCount += 1;
  @override
  Future<void> connect(ScanItem item, {Duration timeout = const Duration(seconds: 15)}) async {
    connectCount += 1;
    lastConnected = item;
    if (connectError != null) {
      throw connectError!;
    }
    connectedItem = item;
    _isConnected$.add(true);
  }
  @override
  Future<void> disconnect() async {
    disconnectCount += 1;
    connectedItem = null;
    _isConnected$.add(false);
  }
  @override
  Future<void> send(List<int> bytes) async {}
  @override
  void clearLogs() {}
  @override
  Future<void> dispose() async => disposeCount += 1;
}
