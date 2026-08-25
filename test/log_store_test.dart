import 'package:blue_app/core/log_entry.dart';
import 'package:blue_app/core/log_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('超过 2000 条丢掉最旧', () {
    final store = LogStore();
    for (var i = 0; i < 2001; i++) {
      store.appendInfo('$i');
    }
    expect(store.entries.length, 2000);
    expect(store.entries.first.message, '1');
    expect(store.entries.last.message, '2000');
  });

  test('appendBytes 写入 hex', () {
    final store = LogStore();
    store.appendBytes(direction: LogDirection.tx, bytes: [0x01, 0xff], message: 'WRITE');
    expect(store.entries.single.hex, '01FF');
    expect(store.entries.single.direction, LogDirection.tx);
  });
}
