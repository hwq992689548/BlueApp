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
  bool useFeasy = false;
  RadioFilter radioFilter = RadioFilter.ble;

  Future<void> setUseFeasy(bool value) async {
    if (value && !feasySupported()) {
      throw UnsupportedError('Feasy 仅 Android/iOS');
    }
    if (value == useFeasy) {
      return;
    }
    useFeasy = value;
    await _rebuild();
  }

  Future<void> setRadioFilter(RadioFilter value) async {
    if (value == RadioFilter.classic && !classicSupported()) {
      throw UnsupportedError('经典蓝牙仅 Android');
    }
    if (value == radioFilter && !useFeasy) {
      return;
    }
    radioFilter = value;
    if (useFeasy) {
      return;
    }
    await _rebuild();
  }

  Future<void> _rebuild() async {
    await _current.stopScan();
    await _current.disconnect();
    await _current.dispose();
    if (useFeasy) {
      _current = createFeasy();
    } else if (radioFilter == RadioFilter.classic) {
      _current = createClassic();
    } else {
      _current = createGatt();
    }
  }
}
