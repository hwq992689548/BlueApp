import 'package:blue_app/core/loop_sender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start 立即发送一次，stop 后不再发送', () async {
    final sent = <List<int>>[];
    final sender = LoopSender(
      send: (bytes) async => sent.add(List<int>.from(bytes)),
      interval: () => const Duration(milliseconds: 20),
    );
    sender.start([0x01]);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(sent.length, 1);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final n = sent.length;
    expect(n, greaterThanOrEqualTo(2));
    sender.stop();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(sent.length, n);
  });

  test('send 失败则 onError 并停止循环', () async {
    var sends = 0;
    Object? captured;
    final sender = LoopSender(
      send: (bytes) async {
        sends += 1;
        throw StateError('radio nak');
      },
      interval: () => const Duration(milliseconds: 20),
      onError: (error, _) => captured = error,
    );
    sender.start([0x01]);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(sends, 1);
    expect(captured, isA<StateError>());
    expect(sender.isRunning, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(sends, 1);
  });

  test('dispose 停止 timer', () async {
    final sent = <List<int>>[];
    final sender = LoopSender(
      send: (bytes) async => sent.add(bytes),
      interval: () => const Duration(milliseconds: 10),
    );
    sender.start([0x02]);
    sender.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(sent.length, 1);
  });
}
