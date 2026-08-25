import 'package:flutter/material.dart';

/// BlueApp色板（挂到 [ThemeData.extensions]）。
@immutable
class BluePalette extends ThemeExtension<BluePalette> {
  /// 构造。
  const BluePalette({
    required this.canvas,
    required this.panel,
    required this.elevated,
    required this.border,
    required this.accent,
    required this.accentInfo,
    required this.warn,
    required this.danger,
    required this.tx,
    required this.rx,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onAccent,
  });

  /// 背景。
  final Color canvas;

  /// 面板 / 卡片。
  final Color panel;

  /// 抬升面。
  final Color elevated;

  /// 描边。
  final Color border;

  /// 主强调。
  final Color accent;

  /// 次强调。
  final Color accentInfo;

  /// 警告。
  final Color warn;

  /// 错误。
  final Color danger;

  /// TX。
  final Color tx;

  /// RX。
  final Color rx;

  /// 主文字。
  final Color textPrimary;

  /// 次文字。
  final Color textSecondary;

  /// 弱文字。
  final Color textMuted;

  /// 强调色上的文字。
  final Color onAccent;

  /// 夜间。
  static const dark = BluePalette(
    canvas: Color(0xFF0B1220),
    panel: Color(0xFF121A2B),
    elevated: Color(0xFF1A2438),
    border: Color(0xFF2A3650),
    accent: Color(0xFF3DDC97),
    accentInfo: Color(0xFF5B8CFF),
    warn: Color(0xFFFFB020),
    danger: Color(0xFFFF5C7A),
    tx: Color(0xFFFF8A5B),
    rx: Color(0xFF3DDC97),
    textPrimary: Color(0xFFE8EEF8),
    textSecondary: Color(0xFF9AA8C2),
    textMuted: Color(0xFF6B7A96),
    onAccent: Color(0xFF04120C),
  );

  /// 白日。
  static const light = BluePalette(
    canvas: Color(0xFFF3F5F9),
    panel: Color(0xFFFFFFFF),
    elevated: Color(0xFFEBEEF5),
    border: Color(0xFFCDD5E4),
    accent: Color(0xFF0C9B6A),
    accentInfo: Color(0xFF3B6FE8),
    warn: Color(0xFFB86E00),
    danger: Color(0xFFD63B5A),
    tx: Color(0xFFC45A2E),
    rx: Color(0xFF0C9B6A),
    textPrimary: Color(0xFF152033),
    textSecondary: Color(0xFF5A6A85),
    textMuted: Color(0xFF8A97AD),
    onAccent: Color(0xFFFFFFFF),
  );

  @override
  BluePalette copyWith({
    Color? canvas,
    Color? panel,
    Color? elevated,
    Color? border,
    Color? accent,
    Color? accentInfo,
    Color? warn,
    Color? danger,
    Color? tx,
    Color? rx,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? onAccent,
  }) {
    return BluePalette(
      canvas: canvas ?? this.canvas,
      panel: panel ?? this.panel,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentInfo: accentInfo ?? this.accentInfo,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
      tx: tx ?? this.tx,
      rx: rx ?? this.rx,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  BluePalette lerp(ThemeExtension<BluePalette>? other, double t) {
    if (other is! BluePalette) {
      return this;
    }
    return BluePalette(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      panel: Color.lerp(panel, other.panel, t) ?? panel,
      elevated: Color.lerp(elevated, other.elevated, t) ?? elevated,
      border: Color.lerp(border, other.border, t) ?? border,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentInfo: Color.lerp(accentInfo, other.accentInfo, t) ?? accentInfo,
      warn: Color.lerp(warn, other.warn, t) ?? warn,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      tx: Color.lerp(tx, other.tx, t) ?? tx,
      rx: Color.lerp(rx, other.rx, t) ?? rx,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
    );
  }
}

/// BlueApp独立视觉体系（不依赖 App / `$lpColors`）。
abstract final class BlueTheme {
  /// 私有构造。
  BlueTheme._();

  /// 当前色板。
  static BluePalette of(BuildContext context) {
    final palette = Theme.of(context).extension<BluePalette>();
    return palette ?? BluePalette.dark;
  }

  /// 等宽日志。
  static TextStyle mono(BuildContext context, {double fontSize = 11.5, Color? color, FontWeight fontWeight = FontWeight.w500}) {
    final palette = of(context);
    return TextStyle(
      fontFamily: 'Menlo',
      fontFamilyFallback: const ['Consolas', 'monospace'],
      fontSize: fontSize,
      height: 1.35,
      color: color ?? palette.textPrimary,
      fontWeight: fontWeight,
    );
  }

  /// 包裹调试宝 Theme。
  static ThemeData theme({required bool light}) {
    final palette = light ? BluePalette.light : BluePalette.dark;
    final brightness = light ? Brightness.light : Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.accent,
        onPrimary: palette.onAccent,
        secondary: palette.accentInfo,
        onSecondary: palette.onAccent,
        error: palette.danger,
        onError: palette.onAccent,
        surface: palette.panel,
        onSurface: palette.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.panel,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: palette.textPrimary, letterSpacing: 0.2),
        shape: Border(bottom: BorderSide(color: palette.border)),
      ),
      dividerColor: palette.border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.elevated,
        contentTextStyle: TextStyle(color: palette.textPrimary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accent;
          }
          return palette.border;
        }),
        checkColor: WidgetStatePropertyAll(palette.onAccent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.elevated,
        isDense: true,
        labelStyle: TextStyle(color: palette.textSecondary, fontSize: 12),
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.accent, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.elevated,
        selectedColor: palette.accent.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: palette.textPrimary, fontSize: 11),
        side: BorderSide(color: palette.border),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      extensions: [palette],
    );
    return base;
  }

  /// 圆角面板装饰。
  static BoxDecoration panelDecoration(BuildContext context, {Color? color, Color? borderColor}) {
    final palette = of(context);
    return BoxDecoration(
      color: color ?? palette.panel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor ?? palette.border),
    );
  }
}
