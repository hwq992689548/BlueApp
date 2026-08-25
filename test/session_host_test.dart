import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/session/session_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('打开 Feasy 会 stopScan、disconnect、dispose 旧会话', () async {
    final gatt = FakeLinkSession(scanKind: ScanKind.ble);
    final feasy = FakeLinkSession(scanKind: ScanKind.feasy);
    var gattMade = 0;
    final host = SessionHost(
      createGatt: () {
        gattMade += 1;
        return gattMade == 1 ? gatt : FakeLinkSession(scanKind: ScanKind.ble);
      },
      createClassic: () => FakeLinkSession(scanKind: ScanKind.classic),
      createFeasy: () => feasy,
      feasySupported: () => true,
      classicSupported: () => true,
    );
    expect(host.current, same(gatt));
    await host.setUseFeasy(true);
    expect(gatt.stopScanCount, 1);
    expect(gatt.disconnectCount, 1);
    expect(gatt.disposeCount, 1);
    expect(host.current, same(feasy));
    expect(host.useFeasy, isTrue);
  });

  test('macOS 打开 Feasy 抛错且不 dispose', () async {
    final gatt = FakeLinkSession(scanKind: ScanKind.ble);
    final host = SessionHost(
      createGatt: () => gatt,
      createClassic: () => FakeLinkSession(scanKind: ScanKind.classic),
      createFeasy: () => FakeLinkSession(scanKind: ScanKind.feasy),
      feasySupported: () => false,
      classicSupported: () => false,
    );
    await expectLater(host.setUseFeasy(true), throwsA(isA<UnsupportedError>()));
    expect(gatt.disposeCount, 0);
    expect(host.current, same(gatt));
  });

  test('Feasy prepare 失败则回滚到 GATT', () async {
    final gatt = FakeLinkSession(scanKind: ScanKind.ble);
    final feasy = FakeLinkSession(scanKind: ScanKind.feasy)..prepareError = Exception('native down');
    var gattMade = 0;
    final host = SessionHost(
      createGatt: () {
        gattMade += 1;
        return gattMade == 1 ? gatt : FakeLinkSession(scanKind: ScanKind.ble);
      },
      createClassic: () => FakeLinkSession(scanKind: ScanKind.classic),
      createFeasy: () => feasy,
      feasySupported: () => true,
      classicSupported: () => true,
    );
    await expectLater(host.setUseFeasy(true), throwsA(isA<Exception>()));
    expect(host.useFeasy, isFalse);
    expect(host.current.scanKind, ScanKind.ble);
    expect(feasy.disposeCount, 1);
  });

  test('切到经典蓝牙会断开 GATT 会话', () async {
    final gatt = FakeLinkSession(scanKind: ScanKind.ble);
    final classic = FakeLinkSession(scanKind: ScanKind.classic);
    final host = SessionHost(
      createGatt: () => gatt,
      createClassic: () => classic,
      createFeasy: () => FakeLinkSession(scanKind: ScanKind.feasy),
      feasySupported: () => true,
      classicSupported: () => true,
    );
    await host.setRadioFilter(RadioFilter.classic);
    expect(gatt.disposeCount, 1);
    expect(host.current, same(classic));
  });
}
