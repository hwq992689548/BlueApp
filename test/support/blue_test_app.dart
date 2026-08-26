import 'package:blue_app/widgets/lp_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试用 [MaterialApp]，带上 LP toast 所需的 [lpToastInit]。
Widget blueTestApp({
  required Widget home,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    builder: (context, child) => lpToastInit(context, child),
    home: home,
  );
}

/// BotToast 用 post-frame 插入，多 pump 一帧才能找到文案。
Future<void> pumpToast(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}
