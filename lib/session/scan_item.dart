import 'package:blue_app/session/scan_kind.dart';

class ScanItem {
  const ScanItem({
    required this.id,
    required this.name,
    required this.rssi,
    required this.kind,
    this.connectable = true,
  });
  final String id;
  final String name;
  final int rssi;
  final ScanKind kind;
  final bool connectable;
}
