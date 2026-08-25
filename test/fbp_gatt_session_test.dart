import 'package:blue_app/session/fbp_gatt_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connect 失败后 connectedItem 为空', () async {
    final session = FbpGattSession();
    addTearDown(session.dispose);
    final item = ScanItem(id: '00:11:22:33:44:55', name: 'Ghost', rssi: -50, kind: ScanKind.ble);
    await expectLater(
      session.connect(item, timeout: const Duration(milliseconds: 400)),
      throwsA(anything),
    );
    expect(session.connectedItem, isNull);
  });
}
