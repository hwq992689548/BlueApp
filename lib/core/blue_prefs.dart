import 'package:shared_preferences/shared_preferences.dart';

/// BlueApp 本机偏好（SharedPreferences）。
class BluePrefs {
  static const useFeasyKey = 'blue.feasy';
  static const keywordKey = 'blue.keyword';
  static const hideInvalidKey = 'blue.hide_invalid';
  static const lightKey = 'blue.light';
  static const hexModeKey = 'blue.hex_mode';
  static const loopMsKey = 'blue.loop_ms';

  static const minLoopMs = 50;
  static const maxLoopMs = 10000;
  static const defaultLoopMs = 200;

  SharedPreferences? _prefs;

  Future<bool> readUseFeasy() async {
    final prefs = await _ensureLoaded();
    return prefs.getBool(useFeasyKey) ?? false;
  }

  Future<void> writeUseFeasy(bool value) async {
    final prefs = await _ensureLoaded();
    await prefs.setBool(useFeasyKey, value);
  }

  Future<String> readKeyword() async {
    final prefs = await _ensureLoaded();
    return prefs.getString(keywordKey) ?? '';
  }

  Future<void> writeKeyword(String value) async {
    final prefs = await _ensureLoaded();
    await prefs.setString(keywordKey, value);
  }

  Future<bool> readHideInvalid() async {
    final prefs = await _ensureLoaded();
    return prefs.getBool(hideInvalidKey) ?? true;
  }

  Future<void> writeHideInvalid(bool value) async {
    final prefs = await _ensureLoaded();
    await prefs.setBool(hideInvalidKey, value);
  }

  Future<bool> readLight() async {
    final prefs = await _ensureLoaded();
    return prefs.getBool(lightKey) ?? false;
  }

  Future<void> writeLight(bool value) async {
    final prefs = await _ensureLoaded();
    await prefs.setBool(lightKey, value);
  }

  Future<bool> readHexMode() async {
    final prefs = await _ensureLoaded();
    return prefs.getBool(hexModeKey) ?? true;
  }

  Future<void> writeHexMode(bool value) async {
    final prefs = await _ensureLoaded();
    await prefs.setBool(hexModeKey, value);
  }

  Future<int> readLoopMs() async {
    final prefs = await _ensureLoaded();
    return prefs.getInt(loopMsKey) ?? defaultLoopMs;
  }

  Future<void> writeLoopMs(int value) async {
    final prefs = await _ensureLoaded();
    final clamped = value.clamp(minLoopMs, maxLoopMs);
    await prefs.setInt(loopMsKey, clamped);
  }

  Future<SharedPreferences> _ensureLoaded() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
