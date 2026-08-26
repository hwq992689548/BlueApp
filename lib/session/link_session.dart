import 'package:blue_app/core/log_entry.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';

abstract class LinkSession {
  bool get hasGattTree;
  ScanKind get scanKind;
  Stream<List<ScanItem>> get scanResults$;
  Stream<bool> get isScanning$;
  Stream<bool> get isConnected$;
  Stream<List<LogEntry>> get logs$;
  Future<bool> isBluetoothOn();
  Future<void> turnOnBluetooth();
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)});
  Future<void> stopScan();
  void clearScanResults();
  ScanItem? get connectedItem;
  Future<void> connect(ScanItem item, {Duration timeout = const Duration(seconds: 15)});
  Future<void> disconnect();
  Future<void> send(List<int> bytes);
  void clearLogs();
  Future<void> dispose();

  /// Feasy 等链路在切过去之后立刻初始化；默认空操作。
  Future<void> prepare() async {}
}
