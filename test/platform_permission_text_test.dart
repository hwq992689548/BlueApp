import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS Info.plist 含蓝牙用途说明', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>NSBluetoothAlwaysUsageDescription</key>'));
    expect(plist, contains('<key>NSBluetoothPeripheralUsageDescription</key>'));
    expect(plist, contains('<string>BlueApp 需要蓝牙扫描、连接设备并收发调试数据。</string>'));
  });

  test('macOS entitlements 打开蓝牙客户端权限', () {
    final debug = File('macos/Runner/DebugProfile.entitlements').readAsStringSync();
    final release = File('macos/Runner/Release.entitlements').readAsStringSync();
    expect(debug, contains('<key>com.apple.security.device.bluetooth</key>'));
    expect(release, contains('<key>com.apple.security.device.bluetooth</key>'));
  });
}
