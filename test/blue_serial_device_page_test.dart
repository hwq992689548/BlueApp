import 'package:blue_app/core/blue_prefs.dart';
import 'package:blue_app/pages/blue_scope.dart';
import 'package:blue_app/pages/blue_serial_device_page.dart';
import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<FakeLinkSession> pumpSerial(WidgetTester tester, {ScanItem? item}) async {
    final session = FakeLinkSession(scanKind: ScanKind.classic);
    final connected = item ?? const ScanItem(id: 'AA:BB', name: 'HC-05', rssi: -40, kind: ScanKind.classic);
    await session.connect(connected);
    final keyword = TextEditingController();
    addTearDown(keyword.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: BlueTheme.theme(light: false),
        home: BlueScope(
          session: session,
          prefs: BluePrefs(),
          lightMode: false,
          hideInvalid: true,
          keywordController: keyword,
          connectingId: null,
          onLightModeToggle: () {},
          onHideInvalidChanged: (_) {},
          onKeywordPersist: (_) {},
          onConnectingIdChanged: (_) {},
          child: Navigator(
            onGenerateInitialRoutes: (_, _) {
              return [
                MaterialPageRoute<void>(builder: (_) => const Scaffold(body: SizedBox.shrink())),
                MaterialPageRoute<void>(builder: (_) => const BlueSerialDevicePage()),
              ];
            },
            onGenerateRoute: (_) {
              return MaterialPageRoute<void>(builder: (_) => const Scaffold(body: SizedBox.shrink()));
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return session;
  }

  testWidgets('AppBar 显示 connectedItem 名称与 id', (tester) async {
    await pumpSerial(tester);
    expect(find.text('HC-05'), findsWidgets);
    expect(find.text('AA:BB'), findsWidgets);
    expect(find.text('CONSOLE'), findsOneWidget);
    expect(find.text('HEX'), findsOneWidget);
    expect(find.text('UTF-8'), findsOneWidget);
  });

  testWidgets('HEX 非法输入 Toast 且不发送', (tester) async {
    final session = await pumpSerial(tester);
    await tester.enterText(find.byKey(const Key('serial-payload')), 'ZZ');
    await tester.tap(find.text('发送'));
    await tester.pump();

    expect(find.textContaining('hex'), findsOneWidget);
    expect(session.sendCount, 0);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('UTF-8 发送走 session.send', (tester) async {
    final session = await pumpSerial(tester);
    await tester.tap(find.text('UTF-8'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('serial-payload')), 'hi');
    await tester.tap(find.text('发送'));
    await tester.pump();

    expect(session.sendCount, 1);
    expect(session.lastSent, [0x68, 0x69]);
  });

  testWidgets('循环发送按间隔调用 send', (tester) async {
    final session = await pumpSerial(tester);
    await tester.enterText(find.byKey(const Key('serial-payload')), '01');
    await tester.enterText(find.byKey(const Key('serial-loop-ms')), '40');
    await tester.tap(find.byKey(const Key('serial-loop')));
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pump();
    expect(session.sendCount, 1);
    await tester.pump(const Duration(milliseconds: 90));
    expect(session.sendCount, greaterThanOrEqualTo(2));
  });

  testWidgets('返回详情页会 disconnect', (tester) async {
    final session = await pumpSerial(tester);
    expect(session.disconnectCount, 0);
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump();
    expect(session.disconnectCount, 1);
  });
}
