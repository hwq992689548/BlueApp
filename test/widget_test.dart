import 'package:blue_app/core/app_names.dart';
import 'package:blue_app/pages/blue_home_page.dart';
import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/blue_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('wideBreakpoint 保持 1000', () {
    expect(BlueHomePage.wideBreakpoint, 1000.0);
  });

  testWidgets('首页标题为蓝宝助手', (tester) async {
    final session = FakeLinkSession(scanKind: ScanKind.ble);
    await tester.pumpWidget(
      blueTestApp(
        home: BlueHomePage(session: session),
      ),
    );
    await tester.pump();
    expect(find.text(AppNames.zh), findsWidgets);
  });

  test('色板对齐 LaserPecker Figma v2 主题黄', () {
    expect(BluePalette.light.accent, const Color(0xFFFAC905));
    expect(BluePalette.dark.accent, const Color(0xFFFACC14));
  });
}
