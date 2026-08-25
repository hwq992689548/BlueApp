import 'package:blue_app/session/fbp_gatt_session.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_characteristic_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 特征操作半屏入口（手机）。
abstract final class BlueCharacteristicSheetSupport {
  BlueCharacteristicSheetSupport._();

  static Future<void> show({
    required BuildContext context,
    required FbpGattSession session,
    required BluetoothCharacteristic characteristic,
  }) {
    final theme = Theme.of(context);
    final palette = BlueTheme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return Theme(
          data: theme,
          child: SafeArea(
            child: BlueCharacteristicPanel(session: session, characteristic: characteristic, showDragHandle: true),
          ),
        );
      },
    );
  }
}
