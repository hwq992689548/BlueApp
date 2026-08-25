import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_scan_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
