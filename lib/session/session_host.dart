import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/session/scan_kind.dart';

class SessionHost {
  SessionHost({
    required this.createGatt,
    required this.createClassic,
    required this.createFeasy,
    required this.feasySupported,
    required this.classicSupported,
  }) : _current = createGatt();

  final LinkSession Function() createGatt;
  final LinkSession Function() createClassic;
  final LinkSession Function() createFeasy;
  final bool Function() feasySupported;
  final bool Function() classicSupported;

  LinkSession _current;
  LinkSession get current => _current;
  bool _useFeasy = false;
  bool get useFeasy => _useFeasy;
  RadioFilter _radioFilter = RadioFilter.ble;
  RadioFilter get radioFilter => _radioFilter;

  Future<void> setUseFeasy(bool value) async {
    if (value && !feasySupported()) {
      throw UnsupportedError('Feasy 仅 Android/iOS');
    }
    if (value == _useFeasy) {
      return;
    }
    final previous = _useFeasy;
    _useFeasy = value;
    try {
      await _rebuild();
    } catch (e) {
      _useFeasy = previous;
      await _rollbackCurrent();
      rethrow;
    }
  }

  Future<void> setRadioFilter(RadioFilter value) async {
    if (value == RadioFilter.classic && !classicSupported()) {
      throw UnsupportedError('经典蓝牙仅 Android');
    }
    if (value == _radioFilter && !_useFeasy) {
      return;
    }
    _radioFilter = value;
    if (_useFeasy) {
      return;
    }
    await _rebuild();
  }

  LinkSession _createCurrent() {
    if (_useFeasy) {
      return createFeasy();
    }
    if (_radioFilter == RadioFilter.classic) {
      return createClassic();
    }
    return createGatt();
  }

  Future<void> _teardown(LinkSession session) async {
    await session.stopScan();
    await session.disconnect();
    await session.dispose();
  }

  Future<void> _rollbackCurrent() async {
    try {
      await _teardown(_current);
    } catch (_) {}
    _current = _createCurrent();
  }

  Future<void> _rebuild() async {
    await _teardown(_current);
    _current = _createCurrent();
    await _current.prepare();
  }
}
