import 'package:flutter/material.dart';

import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/theme/blue_text_styles.dart';

/// 主操作按钮。
class BluePrimaryButton extends StatelessWidget {
  /// 构造。
  const BluePrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false, this.danger = false});

  /// 文案。
  final String label;

  /// 点击。
  final VoidCallback? onPressed;

  /// 加载中。
  final bool busy;

  /// 危险色。
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = BlueTheme.of(context);
    final enabled = onPressed != null && !busy;
    final bg = danger ? palette.danger : palette.accent;
    final radius = BorderRadius.circular(10);
    return Material(
      color: enabled ? bg : palette.border,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: radius,
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: busy
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: palette.textPrimary))
                  : Text(
                      label,
                      style: BlueTextStyles.button.copyWith(color: enabled ? (danger ? palette.textPrimary : palette.onAccent) : palette.textMuted),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
