import 'package:blue_app/core/blue_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loopMs 写入被夹在 50–10000', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = BluePrefs();
    await prefs.writeLoopMs(10);
    expect(await prefs.readLoopMs(), 50);
    await prefs.writeLoopMs(99999);
    expect(await prefs.readLoopMs(), 10000);
  });

  test('Feasy 默认关', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await BluePrefs().readUseFeasy(), isFalse);
  });
}
