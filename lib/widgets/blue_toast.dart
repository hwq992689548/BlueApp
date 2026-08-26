import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/lp_toast.dart';
import 'package:flutter/material.dart';

/// 业务侧入口。实际渲染走从 LP 迁过来的 [$lpToast]。
abstract final class BlueToast {
  BlueToast._();

  static void show(BuildContext context, String message) {
    if (message.isEmpty) {
      return;
    }
    $lpToast.showInfo(message, palette: BlueTheme.of(context));
  }

  static void success(BuildContext context, String message) {
    if (message.isEmpty) {
      return;
    }
    $lpToast.showSuccess(message, palette: BlueTheme.of(context));
  }

  static void warning(BuildContext context, String message) {
    if (message.isEmpty) {
      return;
    }
    $lpToast.showWarning(message, palette: BlueTheme.of(context));
  }

  static void error(BuildContext context, String message) {
    if (message.isEmpty) {
      return;
    }
    $lpToast.showError(message, palette: BlueTheme.of(context));
  }

  static void hide() => $lpToast.cleanAll();
}
