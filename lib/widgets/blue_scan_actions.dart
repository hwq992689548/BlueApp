import 'package:blue_app/session/link_session.dart';

/// Shared scan start/stop with adapter + permission handling.
abstract final class BlueScanActions {
  static bool isPermissionDenied(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('permission') ||
        text.contains('权限') ||
        text.contains('bluetooth_scan') ||
        text.contains('bluetooth_connect') ||
        text.contains('not granted');
  }

  static Future<void> toggleScan({
    required LinkSession session,
    required bool scanning,
    required bool tryTurnOnIfOff,
    required void Function(String message) onToast,
    required void Function(bool denied) onPermissionDenied,
  }) async {
    try {
      if (scanning) {
        await session.stopScan();
        return;
      }
      var bluetoothOn = await session.isBluetoothOn();
      if (!bluetoothOn && tryTurnOnIfOff) {
        try {
          await session.turnOnBluetooth();
        } catch (_) {
          // Adapter may refuse; we re-check isBluetoothOn below.
        }
        bluetoothOn = await session.isBluetoothOn();
      }
      if (!bluetoothOn) {
        onToast('请在系统设置打开蓝牙');
        return;
      }
      await session.startScan();
      onPermissionDenied(false);
    } catch (e) {
      if (isPermissionDenied(e)) {
        onPermissionDenied(true);
        return;
      }
      onToast('$e');
    }
  }
}
