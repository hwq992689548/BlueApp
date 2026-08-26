import 'package:blue_app/session/scan_item.dart';

/// 扫描结果累加器：首次出现顺序固定，后续只原地更新 RSSI / 名称。
class ScanAccumulator {
  final List<String> _order = [];
  final Map<String, ScanItem> _items = {};

  /// 当前列表（首次发现顺序）。
  List<ScanItem> snapshot() => [for (final id in _order) _items[id]!];

  /// 清空。
  void clear() {
    _order.clear();
    _items.clear();
  }

  /// 写入或更新一台设备。空名称不会覆盖已有名称。
  void upsert(ScanItem item) {
    if (item.id.isEmpty) {
      return;
    }
    final existing = _items[item.id];
    if (existing == null) {
      _order.add(item.id);
      _items[item.id] = item;
      return;
    }
    _items[item.id] = ScanItem(
      id: item.id,
      name: item.name.trim().isEmpty ? existing.name : item.name,
      rssi: item.rssi,
      kind: item.kind,
      connectable: item.connectable,
    );
  }
}
