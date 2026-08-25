import 'package:blue_app/pages/blue_home_page.dart';
import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('wideBreakpoint 保持 1000', () {
    expect(BlueHomePage.wideBreakpoint, 1000.0);
  });

  testWidgets('首页标题为 BlueApp', (tester) async {
    final session = FakeLinkSession(scanKind: ScanKind.ble);
    await tester.pumpWidget(
      MaterialApp(
        home: BlueHomePage(session: session),
      ),
    );
    await tester.pump();
    expect(find.text('BlueApp'), findsWidgets);
  });
}
