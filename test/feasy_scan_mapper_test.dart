import 'package:blue_app/session/feasy_scan_mapper.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:feasy_blue_sdk/feasy_blue_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Feasy 扫描项映射', () {
    const device = FeasyBlueScanDevice(address: 'AA', name: 'LP4', rssi: -40);
    final item = feasyScanToItem(device);
    expect(item.id, 'AA');
    expect(item.name, 'LP4');
    expect(item.rssi, -40);
    expect(item.kind, ScanKind.feasy);
    expect(item.connectable, isTrue);
  });
}
