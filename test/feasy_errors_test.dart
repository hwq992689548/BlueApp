import 'package:blue_app/core/feasy_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UnsupportedError 提示仅手机可用', () {
    expect(feasySwitchErrorToast(UnsupportedError('Feasy 仅 Android/iOS')), 'Feasy 仅手机可用');
  });

  test('其它错误提示初始化失败', () {
    expect(feasySwitchErrorToast(Exception('native down')), 'Feasy 初始化失败: Exception: native down');
  });
}
