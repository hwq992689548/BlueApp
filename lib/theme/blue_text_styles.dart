import 'package:flutter/material.dart';

import 'package:blue_app/theme/blue_theme.dart';

/// 调试宝常用文字样式。
abstract final class BlueTextStyles {
  /// 私有构造。
  BlueTextStyles._();

  /// 区块标题。
  static TextStyle section(BuildContext context) {
    final palette = BlueTheme.of(context);
    return TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textSecondary, letterSpacing: 0.8);
  }

  /// 设备名。
  static TextStyle deviceName(BuildContext context) {
    final palette = BlueTheme.of(context);
    return TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary);
  }

  /// 次要行。
  static TextStyle caption(BuildContext context) {
    final palette = BlueTheme.of(context);
    return TextStyle(fontSize: 12, color: palette.textSecondary, height: 1.3);
  }

  /// 按钮。
  static const TextStyle button = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
}
