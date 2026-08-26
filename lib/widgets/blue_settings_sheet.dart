import 'package:blue_app/theme/blue_text_styles.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:flutter/material.dart';

/// 设置半屏：Feasy 开关等。
abstract final class BlueSettingsSheet {
  BlueSettingsSheet._();

  /// 内容下方额外高度。
  static const extraHeight = 50.0;

  /// 弹出设置。
  static Future<void> show({
    required BuildContext context,
    required bool Function() useFeasy,
    required Future<void> Function(bool value)? onUseFeasyChanged,
  }) {
    final palette = BlueTheme.of(context);
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return Theme(
          data: theme,
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('设置', style: BlueTextStyles.section(sheetContext).copyWith(fontSize: 15, letterSpacing: 0.2)),
                    ),
                    SwitchListTile(
                      title: const Text('使用 Feasy 链路'),
                      value: useFeasy(),
                      onChanged: onUseFeasyChanged == null
                          ? null
                          : (value) async {
                              try {
                                await onUseFeasyChanged(value);
                              } catch (_) {
                                // Home already toasts and keeps the switch off.
                              }
                              setSheetState(() {});
                            },
                    ),
                    const SizedBox(height: extraHeight),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
