import 'dart:async';

import 'package:blue_app/core/app_log.dart';
import 'package:blue_app/core/blue_prefs.dart';
import 'package:blue_app/core/hex_support.dart';
import 'package:blue_app/core/loop_sender.dart';
import 'package:blue_app/pages/blue_scope.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/theme/blue_text_styles.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_console_panel.dart';
import 'package:blue_app/widgets/blue_primary_button.dart';
import 'package:flutter/material.dart';

/// 手机窄屏：Feasy / 经典 SPP 串口控制台。
class BlueSerialDevicePage extends StatelessWidget {
  const BlueSerialDevicePage({super.key});

  Future<void> _leaveDetail(BuildContext context, BlueScope scope) async {
    AppLog.info('[UI] 离开串口详情');
    await scope.session.disconnect();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = BlueScope.of(context);
    final palette = BlueTheme.of(context);
    final item = scope.session.connectedItem;
    final name = (item?.name.trim().isNotEmpty ?? false) ? item!.name : '(无名称)';
    final id = item?.id ?? '';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        unawaited(_leaveDetail(context, scope));
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => unawaited(_leaveDetail(context, scope)),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (id.isNotEmpty)
                Text(
                  id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BlueTheme.mono(context, fontSize: 11, color: palette.textSecondary),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: scope.lightMode ? '夜间模式' : '白日模式',
              onPressed: scope.onLightModeToggle,
              icon: Icon(scope.lightMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: palette.textSecondary),
            ),
            StreamBuilder<bool>(
              stream: scope.session.isConnected$,
              initialData: true,
              builder: (context, snapshot) {
                final connected = snapshot.data ?? false;
                if (!connected) {
                  return const SizedBox.shrink();
                }
                return TextButton(
                  onPressed: () => unawaited(_leaveDetail(context, scope)),
                  child: Text(
                    '断开',
                    style: TextStyle(color: palette.danger, fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: BlueConsolePanel(session: scope.session, fillsHeight: true)),
            BlueSerialComposer(session: scope.session, prefs: scope.prefs),
          ],
        ),
      ),
    );
  }
}

/// HEX / UTF-8 发送条，串口页与宽屏详情共用。
class BlueSerialComposer extends StatefulWidget {
  const BlueSerialComposer({super.key, required this.session, this.prefs});

  final LinkSession session;
  final BluePrefs? prefs;

  @override
  State<BlueSerialComposer> createState() => _BlueSerialComposerState();
}

class _BlueSerialComposerState extends State<BlueSerialComposer> {
  final TextEditingController _payloadController = TextEditingController();
  final TextEditingController _loopMsController = TextEditingController(text: '${BluePrefs.defaultLoopMs}');
  late final BluePrefs _prefs;
  late final LoopSender _loopSender;

  bool _hexMode = true;
  bool _loop = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prefs = widget.prefs ?? BluePrefs();
    _loopSender = LoopSender(
      send: widget.session.send,
      interval: () {
        final parsed = int.tryParse(_loopMsController.text.trim());
        final ms = (parsed ?? BluePrefs.defaultLoopMs).clamp(BluePrefs.minLoopMs, BluePrefs.maxLoopMs);
        return Duration(milliseconds: ms);
      },
    );
    unawaited(_loadPrefs());
  }

  Future<void> _loadPrefs() async {
    final hex = await _prefs.readHexMode();
    final ms = await _prefs.readLoopMs();
    if (!mounted) {
      return;
    }
    setState(() {
      _hexMode = hex;
      _loopMsController.text = '$ms';
    });
  }

  @override
  void dispose() {
    _loopSender.dispose();
    _payloadController.dispose();
    _loopMsController.dispose();
    super.dispose();
  }

  List<int>? _parsePayload() {
    final raw = _payloadController.text;
    if (_hexMode) {
      final parsed = HexSupport.parseHex(raw);
      final error = parsed.error;
      if (error != null) {
        _toast(error);
        return null;
      }
      return parsed.bytes;
    }
    return HexSupport.encodeUtf8(raw);
  }

  Future<void> _send() async {
    final bytes = _parsePayload();
    if (bytes == null) {
      return;
    }
    if (_loop) {
      _loopSender.start(bytes);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.session.send(bytes);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = BlueTheme.of(context);
    return Material(
      color: palette.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _modeChip(context, true, 'HEX'),
                const SizedBox(width: 8),
                _modeChip(context, false, 'UTF-8'),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('serial-payload'),
              controller: _payloadController,
              style: BlueTheme.mono(context),
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(hintText: _hexMode ? '01 0A FF' : 'hello'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch.adaptive(
                  key: const Key('serial-loop'),
                  value: _loop,
                  onChanged: (value) {
                    setState(() => _loop = value);
                    if (!value) {
                      _loopSender.stop();
                    }
                  },
                ),
                Text('循环', style: BlueTextStyles.caption(context)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 88,
                  child: TextField(
                    key: const Key('serial-loop-ms'),
                    controller: _loopMsController,
                    keyboardType: TextInputType.number,
                    style: BlueTheme.mono(context, fontSize: 12),
                    decoration: const InputDecoration(hintText: '间隔毫秒', isDense: true),
                    onChanged: (value) {
                      final ms = int.tryParse(value.trim());
                      if (ms != null) {
                        unawaited(_prefs.writeLoopMs(ms));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Text('ms', style: BlueTextStyles.caption(context)),
                const Spacer(),
                BluePrimaryButton(label: '发送', busy: _busy, onPressed: () => unawaited(_send())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(BuildContext context, bool hex, String label) {
    final palette = BlueTheme.of(context);
    final selected = _hexMode == hex;
    return Material(
      color: selected ? palette.accent.withValues(alpha: 0.18) : palette.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? palette.accent : palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() => _hexMode = hex);
          unawaited(_prefs.writeHexMode(hex));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? palette.accent : palette.textSecondary),
          ),
        ),
      ),
    );
  }
}
