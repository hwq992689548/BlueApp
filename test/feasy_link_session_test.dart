import 'package:blue_app/session/feasy_link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:feasy_blue_sdk/feasy_blue_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

ScanItem item(String id) => ScanItem(id: id, name: id, rssi: -40, kind: ScanKind.feasy);

void main() {
  test('其它地址 disconnected 不清掉当前连接', () async {
    final session = FeasyLinkSession();
    addTearDown(session.dispose);
    session.connectedItem = item('AA:AA');
    session.debugEmitConnectionState(
      const FeasyBlueConnectionStateEvent(address: 'BB:BB', state: FeasyBlueConnectionState.disconnected),
    );
    expect(session.connectedItem?.id, 'AA:AA');
  });

  test('其它地址 connected 不把 isConnected 置真', () async {
    final session = FeasyLinkSession();
    addTearDown(session.dispose);
    session.connectedItem = item('AA:AA');
    var connected = false;
    final sub = session.isConnected$.listen((v) => connected = v);
    addTearDown(sub.cancel);
    session.debugEmitConnectionState(
      const FeasyBlueConnectionStateEvent(address: 'BB:BB', state: FeasyBlueConnectionState.connected),
    );
    await Future<void>.delayed(Duration.zero);
    expect(connected, isFalse);
  });

  test('本机地址 disconnected 清除 connectedItem', () async {
    final session = FeasyLinkSession();
    addTearDown(session.dispose);
    session.connectedItem = item('AA:AA');
    session.debugEmitConnectionState(
      const FeasyBlueConnectionStateEvent(address: 'AA:AA', state: FeasyBlueConnectionState.disconnected),
    );
    expect(session.connectedItem, isNull);
  });
}
