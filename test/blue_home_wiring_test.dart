import 'package:blue_app/core/blue_prefs.dart';
import 'package:blue_app/core/feasy_platform.dart';
import 'package:blue_app/pages/blue_home_page.dart';
import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/session/session_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SessionHost buildHost({
  required FakeLinkSession gatt,
  FakeLinkSession? classic,
  FakeLinkSession? feasy,
  bool feasySupported = false,
  bool classicSupported = true,
}) {
  return SessionHost(
    createGatt: () => gatt,
    createClassic: () => classic ?? FakeLinkSession(scanKind: ScanKind.classic),
    createFeasy: () => feasy ?? FakeLinkSession(scanKind: ScanKind.feasy),
    feasySupported: () => feasySupported,
    classicSupported: () => classicSupported,
  );
}

Future<void> pumpHome(
  WidgetTester tester, {
  required SessionHost host,
  BluePrefs? prefs,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlueHomePage(host: host, prefs: prefs ?? BluePrefs()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FeasyPlatform.debugClassicSupported = null;
  });

  tearDown(() {
    FeasyPlatform.debugClassicSupported = null;
  });

  testWidgets('setUseFeasy 抛错则 Toast 且开关保持关', (tester) async {
    final host = buildHost(gatt: FakeLinkSession(scanKind: ScanKind.ble), feasySupported: false);
    await pumpHome(tester, host: host);

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    expect(find.text('使用 Feasy 链路'), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    await tester.pump();

    expect(find.text('Feasy 仅手机可用'), findsOneWidget);
    expect(host.useFeasy, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch).last).value, isFalse);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Android 且 Feasy 关显示低功耗/经典分段', (tester) async {
    final host = buildHost(gatt: FakeLinkSession(scanKind: ScanKind.ble), classicSupported: true);
    await pumpHome(tester, host: host);

    expect(find.text('低功耗'), findsOneWidget);
    expect(find.text('经典'), findsOneWidget);
  });

  testWidgets('Feasy 开或不支持经典时不显示经典分段', (tester) async {
    final gatt = FakeLinkSession(scanKind: ScanKind.ble);
    final feasy = FakeLinkSession(scanKind: ScanKind.feasy);
    final host = buildHost(gatt: gatt, feasy: feasy, feasySupported: true, classicSupported: true);
    await host.setUseFeasy(true);
    await pumpHome(tester, host: host);

    expect(find.text('经典'), findsNothing);
    expect(find.text('低功耗'), findsNothing);
  });

  testWidgets('不支持经典时无低功耗/经典分段', (tester) async {
    final host = buildHost(gatt: FakeLinkSession(scanKind: ScanKind.ble), classicSupported: false);
    await pumpHome(tester, host: host);
    expect(find.text('经典'), findsNothing);
    expect(find.text('低功耗'), findsNothing);
  });

  testWidgets('连接成功 hasGattTree 进入 GATT 页', (tester) async {
    final gatt = FakeLinkSession(scanKind: ScanKind.ble);
    gatt.emitScanResults(const [
      ScanItem(id: 'aa', name: 'Sensor', rssi: -40, kind: ScanKind.ble),
    ]);
    await pumpHome(tester, host: buildHost(gatt: gatt));
    await tester.tap(find.text('连接'));
    await tester.pumpAndSettle();
    expect(find.text('设备详情'), findsOneWidget);
  });

  testWidgets('连接成功无 GATT 树进入串口页', (tester) async {
    final classic = FakeLinkSession(scanKind: ScanKind.classic);
    classic.emitScanResults(const [
      ScanItem(id: 'CC:DD', name: 'SPP-Mod', rssi: -50, kind: ScanKind.classic),
    ]);
    final host = buildHost(
      gatt: FakeLinkSession(scanKind: ScanKind.ble),
      classic: classic,
      classicSupported: true,
    );
    await host.setRadioFilter(RadioFilter.classic);
    await pumpHome(tester, host: host);
    await tester.tap(find.text('连接'));
    await tester.pumpAndSettle();
    expect(find.text('SPP-Mod'), findsWidgets);
    expect(find.text('CC:DD'), findsWidgets);
    expect(find.text('发送'), findsOneWidget);
    expect(find.text('设备详情'), findsNothing);
  });

  testWidgets('启动时读取 Feasy 偏好，不支持则保持关', (tester) async {
    SharedPreferences.setMockInitialValues({BluePrefs.useFeasyKey: true});
    final host = buildHost(gatt: FakeLinkSession(scanKind: ScanKind.ble), feasySupported: false);
    await pumpHome(tester, host: host, prefs: BluePrefs());
    await tester.pump();
    expect(host.useFeasy, isFalse);
  });

  testWidgets('启动时读取 Feasy 偏好，支持则打开', (tester) async {
    SharedPreferences.setMockInitialValues({BluePrefs.useFeasyKey: true});
    final feasy = FakeLinkSession(scanKind: ScanKind.feasy);
    final host = buildHost(
      gatt: FakeLinkSession(scanKind: ScanKind.ble),
      feasy: feasy,
      feasySupported: true,
    );
    await pumpHome(tester, host: host, prefs: BluePrefs());
    await tester.pump();
    expect(host.useFeasy, isTrue);
    expect(host.current, same(feasy));
  });
}
