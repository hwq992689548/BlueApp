import 'package:blue_app/core/blue_prefs.dart';
import 'package:blue_app/pages/blue_gatt_device_page.dart';
import 'package:blue_app/pages/blue_scope.dart';
import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_item.dart';
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

  testWidgets('返回详情页会 disconnect', (tester) async {
    final session = FakeLinkSession(scanKind: ScanKind.ble);
    await session.connect(const ScanItem(id: 'aa', name: 'Sensor', rssi: -40, kind: ScanKind.ble));
    final keyword = TextEditingController();

    await tester.pumpWidget(
      blueTestApp(
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
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: SizedBox.shrink()),
                ),
                MaterialPageRoute<void>(
                  builder: (_) => const BlueGattDevicePage(),
                ),
              ];
            },
            onGenerateRoute: (settings) {
              return MaterialPageRoute<void>(builder: (_) => const Scaffold(body: SizedBox.shrink()));
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(session.disconnectCount, 0);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump();

    expect(session.disconnectCount, 1);
  });
}
