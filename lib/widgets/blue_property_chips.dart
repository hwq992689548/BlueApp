import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:blue_app/theme/blue_theme.dart';

/// 特征属性小标签（READ / WRITE / NOTIFY 等）。
class BluePropertyChips extends StatelessWidget {
  /// 构造。
  const BluePropertyChips({super.key, required this.properties, this.compact = false});

  /// 属性。
  final CharacteristicProperties properties;

  /// 列表行更紧凑。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = BlueTheme.of(context);
    final chips = <({String label, Color color})>[
      if (properties.read) (label: 'Read', color: palette.accentInfo),
      if (properties.write) (label: 'Write', color: palette.accent),
      if (properties.writeWithoutResponse) (label: 'Write·NoRsp', color: palette.tx),
      if (properties.notify) (label: 'Notify', color: palette.rx),
      if (properties.indicate) (label: 'Indicate', color: palette.warn),
    ];
    if (chips.isEmpty) {
      return Text(
        '—',
        style: TextStyle(fontSize: compact ? 10 : 11, color: palette.textMuted),
      );
    }
    return Wrap(spacing: compact ? 4 : 6, runSpacing: compact ? 4 : 6, children: [for (final chip in chips) _chip(context, chip.label, chip.color)]);
  }

  /// 单个标签。
  Widget _chip(BuildContext context, String label, Color color) {
    final compact = this.compact;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(compact ? 4 : 5),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: compact ? 9.5 : 10, fontWeight: FontWeight.w700, letterSpacing: 0.2, color: color, height: 1.1),
      ),
    );
  }
}
