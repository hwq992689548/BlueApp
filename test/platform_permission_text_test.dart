import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS Info.plist 含蓝牙用途说明', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>NSBluetoothAlwaysUsageDescription</key>'));
    expect(plist, contains('<key>NSBluetoothPeripheralUsageDescription</key>'));
    expect(plist, contains('<string>BlueApp 需要蓝牙扫描、连接设备并收发调试数据。</string>'));
  });

  test('macOS Info.plist 含蓝牙用途说明', () {
    final plist = File('macos/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>NSBluetoothAlwaysUsageDescription</key>'));
    expect(plist, contains('<string>BlueApp 需要蓝牙扫描、连接设备并收发调试数据。</string>'));
  });

  test('Android 经典扫描需要位置，BLUETOOTH_SCAN 不含 neverForLocation', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(manifest.contains('neverForLocation'), isFalse);
  });

  test('macOS entitlements 打开蓝牙客户端权限', () {
    final debug = File('macos/Runner/DebugProfile.entitlements').readAsStringSync();
    final release = File('macos/Runner/Release.entitlements').readAsStringSync();
    expect(debug, contains('<key>com.apple.security.device.bluetooth</key>'));
    expect(release, contains('<key>com.apple.security.device.bluetooth</key>'));
  });
}
