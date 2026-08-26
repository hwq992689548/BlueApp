import 'package:blue_app/core/log_entry.dart';
import 'package:blue_app/session/fake_link_session.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_console_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/blue_test_app.dart';

void main() {
  test('导出文本含 ISO 时间、方向、hex、ascii、message', () {
    final at = DateTime.utc(2026, 8, 25, 8, 45, 0);
    final text = BlueConsolePanel.exportText([
      LogEntry(at: at, direction: LogDirection.tx, hex: '01FF', ascii: '.', message: 'WRITE'),
    ]);
    expect(text, contains(at.toIso8601String()));
    expect(text, contains('tx'));
    expect(text, contains('01FF'));
    expect(text, contains('.'));
    expect(text, contains('WRITE'));
  });

  testWidgets('导出写入剪贴板并 Toast 已复制', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments;
        if (args is Map) {
          copied = args['text'] as String?;
        }
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    final session = FakeLinkSession(scanKind: ScanKind.ble);
    session.emitLogs([
      LogEntry(at: DateTime.utc(2026, 8, 25), direction: LogDirection.info, hex: '', message: 'hello'),
    ]);

    await tester.pumpWidget(
      blueTestApp(
        theme: BlueTheme.theme(light: false),
        home: Scaffold(
          body: BlueConsolePanel(session: session, fillsHeight: true),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('导出'));
    await pumpToast(tester);

    expect(copied, contains('hello'));
    expect(find.text('已复制'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
