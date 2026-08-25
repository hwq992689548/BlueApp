import 'package:blue_app/core/invalid_device.dart';
import 'package:blue_app/core/scan_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('无名称且不可连接为无效', () {
    expect(InvalidDevice.isInvalid(advName: '', platformName: '', connectable: false), isTrue);
  });

  test('仅有平台名且可连接为有效', () {
    expect(InvalidDevice.isInvalid(advName: '', platformName: 'LP4', connectable: true), isFalse);
  });

  test('有名称但不可连接为无效', () {
    expect(InvalidDevice.isInvalid(advName: 'x', platformName: '', connectable: false), isTrue);
  });

  test('屏蔽无效时过滤无名称', () {
    expect(
      ScanFilter.shouldShow(
        keyword: '',
        hideInvalid: true,
        advName: '',
        platformName: '',
        remoteId: 'AA:BB',
        connectable: true,
      ),
      isFalse,
    );
  });

  test('关键词匹配 remoteId', () {
    expect(
      ScanFilter.shouldShow(
        keyword: 'aa:bb',
        hideInvalid: false,
        advName: '',
        platformName: '',
        remoteId: 'AA:BB:CC',
        connectable: false,
      ),
      isTrue,
    );
  });
}
