import 'dart:async';

import 'package:blue_app/core/feasy_platform.dart';
import 'package:blue_app/session/classic_spp_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/spp/classic_spp_channel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClassicSppChannel extends ClassicSppChannel {
  FakeClassicSppChannel({this.connectDelay = const Duration(seconds: 30)});

  final Duration connectDelay;
  int disconnectCalls = 0;
  int requestPermissionCalls = 0;
  final _events = StreamController<Map<dynamic, dynamic>>.broadcast();

  @override
  Future<void> connect(String address) => Future<void>.delayed(connectDelay);

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
  }

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> requestPermissions() async {
    requestPermissionCalls += 1;
  }

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<List<Map<dynamic, dynamic>>> bondedDevices() async => [];

  @override
  Stream<Map<dynamic, dynamic>> observe() => _events.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    FeasyPlatform.debugClassicSupported = null;
  });

  test('connect timeout 覆盖整段连接并调用 disconnect', () async {
    FeasyPlatform.debugClassicSupported = true;
    final fake = FakeClassicSppChannel(connectDelay: const Duration(seconds: 30));
    final session = ClassicSppSession(channel: fake);
    addTearDown(session.dispose);

    final item = ScanItem(
      id: 'AA:BB:CC:DD:EE:FF',
      name: 'HC-05',
      rssi: -50,
      kind: ScanKind.classic,
      connectable: true,
    );

    await expectLater(
      session.connect(item, timeout: const Duration(milliseconds: 80)),
      throwsA(isA<TimeoutException>()),
    );

    // start-of-connect disconnect + failure-path disconnect
    expect(fake.disconnectCalls, greaterThanOrEqualTo(2));
    expect(session.connectedItem, isNull);
  });

  test('startScan 先请求运行时权限再 discovery', () async {
    FeasyPlatform.debugClassicSupported = true;
    final fake = FakeClassicSppChannel();
    final session = ClassicSppSession(channel: fake);
    addTearDown(session.dispose);
    await session.startScan(timeout: const Duration(milliseconds: 50));
    expect(fake.requestPermissionCalls, 1);
  });
}
