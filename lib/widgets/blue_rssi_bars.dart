import 'package:flutter/material.dart';

import 'package:blue_app/theme/blue_theme.dart';

/// RSSI 条形指示。
class BlueRssiBars extends StatelessWidget {
  /// 构造。
  const BlueRssiBars({super.key, required this.rssi});

  /// 信号强度。
  final int rssi;

  /// 0~4 格。
  int get _level {
    if (rssi >= -55) {
      return 4;
    }
    if (rssi >= -65) {
      return 3;
    }
    if (rssi >= -75) {
      return 2;
    }
    if (rssi >= -85) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = BlueTheme.of(context);
    final level = _level;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 1; i <= 4; i++)
          Container(
            width: 3.5,
            height: 4.0 + i * 3.2,
            margin: const EdgeInsets.only(left: 1.5),
            decoration: BoxDecoration(color: i <= level ? palette.accent : palette.border, borderRadius: BorderRadius.circular(1)),
          ),
      ],
    );
  }
}
