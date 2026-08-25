import 'package:blue_app/core/hex_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('解析带分隔 hex', () {
    final parsed = HexSupport.parseHex('01 0a:FF');
    expect(parsed.error, isNull);
    expect(parsed.bytes, [0x01, 0x0a, 0xff]);
    expect(HexSupport.bytesToHex(parsed.bytes ?? const []), '010AFF');
  });

  test('奇数长度报错', () {
    final parsed = HexSupport.parseHex('abc');
    expect(parsed.bytes, isNull);
    expect(parsed.error, 'hex 长度须为偶数');
  });

  test('空 hex 报错', () {
    expect(HexSupport.parseHex('').error, 'hex 为空');
  });

  test('非法字符报错', () {
    expect(HexSupport.parseHex('GG').error, 'hex 含非法字符');
  });
}
