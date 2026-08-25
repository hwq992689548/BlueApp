import 'dart:convert';
import 'dart:typed_data';

/// BlueApp：hex / UTF-8 编解码。
abstract final class HexSupport {
  /// 私有构造。
  HexSupport._();

  /// 字节转连续大写 hex（无分隔）。
  static String bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }

  /// 解析 hex 字符串；允许空格与 `:` `-` 分隔。
  static ({Uint8List? bytes, String? error}) parseHex(String input) {
    final compact = input.replaceAll(RegExp(r'[\s:\-]'), '');
    if (compact.isEmpty) {
      return (bytes: null, error: 'hex 为空');
    }
    if (compact.length.isOdd) {
      return (bytes: null, error: 'hex 长度须为偶数');
    }
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(compact)) {
      return (bytes: null, error: 'hex 含非法字符');
    }
    final out = Uint8List(compact.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(compact.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return (bytes: out, error: null);
  }

  /// UTF-8 编码文本。
  static Uint8List encodeUtf8(String input) => Uint8List.fromList(utf8.encode(input));

  /// 可打印 ASCII 预览；不可打印用 `.`。
  static String bytesToAsciiPreview(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte >= 0x20 && byte <= 0x7e) {
        buffer.writeCharCode(byte);
      } else {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}
