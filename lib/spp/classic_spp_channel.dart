import 'package:flutter/services.dart';

class ClassicSppChannel {
  static const method = MethodChannel('com.feixiang.blueapp/spp');
  static const events = EventChannel('com.feixiang.blueapp/spp_events');

  Future<void> startDiscovery() => method.invokeMethod('startDiscovery');

  Future<void> stopDiscovery() => method.invokeMethod('stopDiscovery');

  Future<List<Map<dynamic, dynamic>>> bondedDevices() async {
    final raw = await method.invokeMethod<List<dynamic>>('bondedDevices') ?? [];
    return raw.cast<Map<dynamic, dynamic>>();
  }

  Future<void> connect(String address) => method.invokeMethod('connect', {'address': address});

  Future<void> requestPermissions() async {
    await method.invokeMethod('requestPermissions');
  }

  Future<void> disconnect() => method.invokeMethod('disconnect');

  Future<void> write(Uint8List data) => method.invokeMethod('write', {'data': data});

  Stream<Map<dynamic, dynamic>> observe() =>
      events.receiveBroadcastStream().map((e) => Map<dynamic, dynamic>.from(e as Map));
}
