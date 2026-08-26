import 'package:blue_app/theme/blue_theme.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 从 laserpecker-flutter `lp_share` 的 `$lpToast` 迁过来。
/// 不依赖 `lp_share`（会把整套 App 模块拖进来），只搬 toast 本体 + 图标。
///
/// 使用要点：
/// 1. 需要调用 [lpToastInit] 包裹 [MaterialApp.builder]
/// 2. 如果需要使用 [LpToast.showLoading]，需要往 `navigatorObservers` 中添加 [lpToastNavigatorObserver]
Widget lpToastInit(BuildContext context, Widget? child) {
  final toastInit = BotToastInit();
  return toastInit(context, child);
}

NavigatorObserver get lpToastNavigatorObserver => BotToastNavigatorObserver();

const Duration _duration = Duration(seconds: 2);
const Alignment _align = Alignment(0, -0.2);
const bool _clickClose = true;
const EdgeInsetsGeometry _padding = EdgeInsets.symmetric(vertical: 14, horizontal: 18);
const TextStyle _textStyle = TextStyle(fontSize: 14, color: Colors.white);
const Color _bgColor = Colors.transparent;

enum LpNotifyType {
  info,
  accent,
  success,
  warn,
  error;

  String get iconAsset {
    switch (this) {
      case LpNotifyType.info:
        return 'assets/svg/toast/toast_info.svg';
      case LpNotifyType.success:
        return 'assets/svg/toast/toast_success.svg';
      case LpNotifyType.warn:
        return 'assets/svg/toast/toast_warning.svg';
      case LpNotifyType.accent:
        return 'assets/svg/toast/toast_accent.svg';
      case LpNotifyType.error:
        return 'assets/svg/toast/toast_error.svg';
    }
  }
}

VoidCallback? _stickyWarningNotificationCancel;

Widget _lpNotificationToastContent({
  required LpNotifyType type,
  required String message,
  required BluePalette palette,
}) {
  return IgnorePointer(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: palette.panel,
            boxShadow: [
              BoxShadow(offset: const Offset(0, 2), blurRadius: 3, color: Colors.black.withValues(alpha: 0.08)),
            ],
            borderRadius: BorderRadius.circular(22),
          ),
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(type.iconAsset, width: 20, height: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  maxLines: 20,
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: palette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final $lpToast = LpToast._internal();

class LpToast {
  LpToast._internal();

  void showInfo(String message, {BluePalette? palette}) => _showNotification(type: LpNotifyType.info, message: message, palette: palette);

  void showSuccess(String message, {BluePalette? palette}) => _showNotification(type: LpNotifyType.success, message: message, palette: palette);

  void showWarning(String message, {BluePalette? palette}) => _showNotification(type: LpNotifyType.warn, message: message, palette: palette);

  void showError(String message, {BluePalette? palette}) => _showNotification(type: LpNotifyType.error, message: message, palette: palette);

  void _showNotification({required LpNotifyType type, required String message, BluePalette? palette}) {
    final colors = palette ?? BluePalette.dark;
    BotToast.showCustomNotification(
      align: const Alignment(0, -1),
      toastBuilder: (_) => _lpNotificationToastContent(type: type, message: message, palette: colors),
      enableSlideOff: false,
    );
  }

  void cleanAll() => BotToast.cleanAll();
}

extension LpToastExt on LpToast {
  VoidCallback showText(
    String? text, {
    Color backgroundColor = _bgColor,
    Duration duration = _duration,
    TextStyle textStyle = _textStyle,
    Alignment alignment = _align,
    bool clickClose = _clickClose,
    EdgeInsetsGeometry padding = _padding,
    VoidCallback? onClose,
  }) {
    if (text == null || text == '') {
      return () {};
    }
    return BotToast.showText(
      text: text,
      backgroundColor: backgroundColor,
      duration: duration,
      textStyle: textStyle,
      align: alignment,
      clickClose: clickClose,
      contentPadding: padding,
      onClose: onClose,
    );
  }

  VoidCallback showLoading({
    String? text,
    Color backgroundColor = _bgColor,
    Alignment alignment = _align,
    bool allowClick = false,
    bool clickClose = false,
    VoidCallback? onClose,
  }) {
    return BotToast.showCustomLoading(
      backgroundColor: backgroundColor,
      align: alignment,
      allowClick: allowClick,
      clickClose: clickClose,
      onClose: onClose,
      toastBuilder: (cancelFn) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, text == null ? 24 : 12),
          constraints: const BoxConstraints(minWidth: 120, minHeight: 90),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white)),
              if (text != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void dismissLoading() => BotToast.closeAllLoading();

  bool get isStickyWarningActive => _stickyWarningNotificationCancel != null;

  VoidCallback showWarningSticky(String message, {BluePalette? palette}) {
    _stickyWarningNotificationCancel?.call();
    final colors = palette ?? BluePalette.dark;
    final cancel = BotToast.showCustomNotification(
      align: const Alignment(0, -1),
      duration: null,
      toastBuilder: (_) => _lpNotificationToastContent(type: LpNotifyType.warn, message: message, palette: colors),
    );
    _stickyWarningNotificationCancel = cancel;
    return () {
      cancel();
      if (_stickyWarningNotificationCancel == cancel) {
        _stickyWarningNotificationCancel = null;
      }
    };
  }

  void dismissStickyWarning() {
    _stickyWarningNotificationCancel?.call();
    _stickyWarningNotificationCancel = null;
  }
}
