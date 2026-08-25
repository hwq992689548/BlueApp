import 'package:flutter/material.dart';

import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/theme/blue_text_styles.dart';

/// 次要描边按钮。
class BlueOutlineButton extends StatelessWidget {
  /// 构造。
  const BlueOutlineButton({super.key, required this.label, required this.onPressed});

  /// 文案。
  final String label;

  /// 点击。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = BlueTheme.of(context);
    final radius = BorderRadius.circular(10);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                label,
                style: BlueTextStyles.button.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
