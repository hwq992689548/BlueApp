import 'package:blue_app/session/scan_accumulator.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:flutter_test/flutter_test.dart';

ScanItem item(String id, {String name = '', int rssi = -80}) {
  return ScanItem(id: id, name: name, rssi: rssi, kind: ScanKind.ble);
}

void main() {
  test('RSSI 变化不打乱首次发现顺序', () {
    final acc = ScanAccumulator();
    acc.upsert(item('aa', name: 'A', rssi: -90));
    acc.upsert(item('bb', name: 'B', rssi: -40));
    acc.upsert(item('aa', name: 'A', rssi: -30));
    acc.upsert(item('cc', name: 'C', rssi: -20));

    expect(acc.snapshot().map((e) => e.id).toList(), ['aa', 'bb', 'cc']);
    expect(acc.snapshot().first.rssi, -30);
  });

  test('空名称不覆盖已有名称', () {
    final acc = ScanAccumulator();
    acc.upsert(item('aa', name: 'LaserPecker'));
    acc.upsert(item('aa', name: '', rssi: -50));

    expect(acc.snapshot().single.name, 'LaserPecker');
    expect(acc.snapshot().single.rssi, -50);
  });

  test('clear 后重新累计', () {
    final acc = ScanAccumulator();
    acc.upsert(item('aa', name: 'A'));
    acc.clear();
    acc.upsert(item('bb', name: 'B'));
    expect(acc.snapshot().map((e) => e.id).toList(), ['bb']);
  });
}
