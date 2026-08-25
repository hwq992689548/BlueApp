import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_scan_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpPane(
  WidgetTester tester,
  FakeLinkSession session, {
  bool tryTurnOnIfOff = false,
  bool showClassicFilter = false,
  bool compact = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: BlueTheme.theme(light: false),
      home: Scaffold(
        body: BlueScanPane(
          session: session,
          keywordController: TextEditingController(),
          hideInvalid: false,
          onHideInvalidChanged: (_) {},
          connectingId: null,
          onConnectingIdChanged: (_) {},
          onConnectSucceeded: () {},
          tryTurnOnIfOff: tryTurnOnIfOff,
          showClassicFilter: showClassicFilter,
          compact: compact,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('扫描列表按 ScanFilter 过滤并显示 kind 标签', (tester) async {
    final session = FakeLinkSession(scanKind: ScanKind.ble);
    final keyword = TextEditingController();
    session.emitScanResults(const [
      ScanItem(id: 'aa', name: 'Sensor', rssi: -40, kind: ScanKind.ble),
      ScanItem(id: 'bb', name: '', rssi: -50, kind: ScanKind.classic, connectable: false),
      ScanItem(id: 'cc', name: 'FeasyMod', rssi: -60, kind: ScanKind.feasy),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: BlueTheme.theme(light: false),
        home: Scaffold(
          body: BlueScanPane(
            session: session,
            keywordController: keyword,
            hideInvalid: true,
            onHideInvalidChanged: (_) {},
            connectingId: null,
            onConnectingIdChanged: (_) {},
            onConnectSucceeded: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sensor'), findsOneWidget);
    expect(find.text('FeasyMod'), findsOneWidget);
    expect(find.text('BLE'), findsWidgets);
    expect(find.text('Feasy'), findsOneWidget);
    expect(find.text('Classic'), findsNothing);

    keyword.text = 'Sen';
    await tester.pump();
    expect(find.text('Sensor'), findsOneWidget);
    expect(find.text('FeasyMod'), findsNothing);
  });

  testWidgets('连接失败 Toast 且留在扫描页', (tester) async {
    final session = FakeLinkSession(scanKind: ScanKind.ble);
    session.connectError = Exception('timeout');
    session.emitScanResults(const [
      ScanItem(id: 'aa', name: 'Sensor', rssi: -40, kind: ScanKind.ble),
    ]);
    var succeeded = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: BlueTheme.theme(light: false),
        home: Scaffold(
          body: BlueScanPane(
            session: session,
            keywordController: TextEditingController(),
            hideInvalid: false,
            onHideInvalidChanged: (_) {},
            connectingId: null,
            onConnectingIdChanged: (_) {},
            onConnectSucceeded: () => succeeded = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('连接'));
    await tester.pump();

    expect(succeeded, isFalse);
    expect(find.textContaining('连接失败'), findsOneWidget);
    expect(find.text('SCANNER'), findsOneWidget);
    expect(session.connectCount, 1);
    expect(session.lastConnected?.id, 'aa');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('蓝牙关闭且开启失败 Toast 请在系统设置打开蓝牙', (tester) async {
    final session = FakeLinkSession(scanKind: ScanKind.ble);
    session.bluetoothOn = false;
    session.turnOnError = Exception('denied');
    await pumpPane(tester, session, tryTurnOnIfOff: true, compact: true);
    await tester.pump();
    await tester.tap(find.text('扫描'));
    await tester.pump();

    expect(session.turnOnCount, 1);
    expect(session.startScanCount, 0);
    expect(find.text('请在系统设置打开蓝牙'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('权限拒绝时页面显示无法扫描且不崩溃', (tester) async {
    final session = FakeLinkSession(scanKind: ScanKind.ble);
    session.startScanError = Exception('BLUETOOTH_SCAN permission denied');
    await pumpPane(tester, session, compact: true);
    await tester.pump();
    await tester.tap(find.text('扫描'));
    await tester.pump();

    expect(find.text('没有蓝牙权限，无法扫描'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showClassicFilter 时显示低功耗/经典分段', (tester) async {
    final session = FakeLinkSession(scanKind: ScanKind.ble);
    await pumpPane(tester, session, showClassicFilter: true);
    await tester.pump();
    expect(find.text('低功耗'), findsOneWidget);
    expect(find.text('经典'), findsOneWidget);
  });
}
