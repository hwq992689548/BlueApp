import 'package:blue_app/spp/classic_spp_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connect 走 MethodChannel', () async {
    const channel = MethodChannel('com.feixiang.blueapp/spp');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    final spp = ClassicSppChannel();
    await spp.connect('AA:BB:CC:DD:EE:FF');
    expect(calls, ['connect']);
  });
}
