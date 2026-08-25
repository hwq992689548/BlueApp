import 'dart:async';

import 'package:blue_app/core/blue_prefs.dart';
import 'package:blue_app/core/hex_support.dart';
import 'package:blue_app/core/loop_sender.dart';
import 'package:blue_app/session/fbp_gatt_session.dart';
import 'package:blue_app/theme/blue_text_styles.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_primary_button.dart';
import 'package:blue_app/widgets/blue_property_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 特征 Read / Write / Notify 面板（半屏与宽屏内嵌共用）。
class BlueCharacteristicPanel extends StatefulWidget {
  const BlueCharacteristicPanel({
    super.key,
    required this.session,
    required this.characteristic,
    this.showDragHandle = false,
    this.expanded = false,
    this.prefs,
  });

  final FbpGattSession session;
  final BluetoothCharacteristic characteristic;
  final bool showDragHandle;
  final bool expanded;
  final BluePrefs? prefs;

  @override
  State<BlueCharacteristicPanel> createState() => _BlueCharacteristicPanelState();
}

class _BlueCharacteristicPanelState extends State<BlueCharacteristicPanel> {
  final TextEditingController _payloadController = TextEditingController();
  final TextEditingController _loopMsController = TextEditingController(text: '${BluePrefs.defaultLoopMs}');
  late final BluePrefs _prefs;
  late final LoopSender _loopSender;

  bool _hexMode = true;
  bool _notifyOn = false;
  bool _busy = false;
  bool _loop = false;
  String _lastHex = '';

  CharacteristicProperties get _props => widget.characteristic.properties;

  @override
  void initState() {
    super.initState();
    _prefs = widget.prefs ?? BluePrefs();
    _loopSender = LoopSender(
      send: (bytes) => widget.session.writeCharacteristic(
        widget.characteristic,
        bytes,
        withoutResponse: !_props.write && _props.writeWithoutResponse,
      ),
      interval: () {
        final parsed = int.tryParse(_loopMsController.text.trim());
        final ms = (parsed ?? BluePrefs.defaultLoopMs).clamp(BluePrefs.minLoopMs, BluePrefs.maxLoopMs);
        return Duration(milliseconds: ms);
      },
    );
    unawaited(_loadLoopMs());
  }

  Future<void> _loadLoopMs() async {
    final ms = await _prefs.readLoopMs();
    if (mounted) {
      _loopMsController.text = '$ms';
    }
  }

  @override
  void didUpdateWidget(covariant BlueCharacteristicPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characteristic.uuid != widget.characteristic.uuid) {
      _loopSender.stop();
      _payloadController.clear();
      _hexMode = true;
      _notifyOn = false;
      _busy = false;
      _loop = false;
      _lastHex = '';
    }
  }

  @override
  void dispose() {
    _loopSender.stop();
    _payloadController.dispose();
    _loopMsController.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    setState(() => _busy = true);
    try {
      final value = await widget.session.readCharacteristic(widget.characteristic);
      setState(() => _lastHex = HexSupport.bytesToHex(value));
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
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

  Future<void> _write() async {
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
      final withoutResponse = !_props.write && _props.writeWithoutResponse;
      await widget.session.writeCharacteristic(widget.characteristic, bytes, withoutResponse: withoutResponse);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _toggleNotify() async {
    setState(() => _busy = true);
    try {
      final next = !_notifyOn;
      await widget.session.setNotify(widget.characteristic, next);
      setState(() => _notifyOn = next);
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
    final canWrite = _props.write || _props.writeWithoutResponse;
    final canNotify = _props.notify || _props.indicate;
    final bottomInset = widget.showDragHandle ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    final body = Column(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDragHandle) ...[
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text('CHARACTERISTIC', style: BlueTextStyles.section(context)),
        const SizedBox(height: 6),
        Text(widget.characteristic.uuid.str, style: BlueTextStyles.deviceName(context).copyWith(fontSize: 14)),
        Text('service ${widget.characteristic.serviceUuid.str}', style: BlueTextStyles.caption(context)),
        const SizedBox(height: 8),
        BluePropertyChips(properties: _props),
        if (_lastHex.isNotEmpty) ...[const SizedBox(height: 8), Text('LAST  $_lastHex', style: BlueTheme.mono(context, color: palette.rx))],
        if (_props.read) ...[const SizedBox(height: 12), BluePrimaryButton(label: 'READ', busy: _busy, onPressed: () => unawaited(_read()))],
        if (canNotify) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: palette.elevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _notifyOn ? palette.rx.withValues(alpha: 0.55) : palette.border),
            ),
            child: Row(
              children: [
                Icon(
                  _props.indicate ? Icons.campaign_outlined : Icons.notifications_active_outlined,
                  size: 18,
                  color: _notifyOn ? palette.rx : palette.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _props.indicate ? 'Indicate' : 'Notify',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary),
                      ),
                      Text(
                        _notifyOn ? 'On · receiving' : 'Off',
                        style: BlueTextStyles.caption(context).copyWith(color: _notifyOn ? palette.rx : palette.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _notifyOn,
                  activeThumbColor: palette.onAccent,
                  activeTrackColor: palette.rx,
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value == _notifyOn) {
                            return;
                          }
                          unawaited(_toggleNotify());
                        },
                ),
              ],
            ),
          ),
        ],
        if (canWrite) ...[
          const SizedBox(height: 12),
          Row(children: [_modeChip(context, true, 'HEX'), const SizedBox(width: 8), _modeChip(context, false, 'ASCII')]),
          const SizedBox(height: 8),
          if (widget.expanded)
            Expanded(
              child: TextField(
                controller: _payloadController,
                style: BlueTheme.mono(context),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(hintText: _hexMode ? '01 0A FF' : 'hello', alignLabelWithHint: true),
              ),
            )
          else
            TextField(
              controller: _payloadController,
              style: BlueTheme.mono(context),
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(hintText: _hexMode ? '01 0A FF' : 'hello'),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _loop,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) {
                    final next = value ?? false;
                    setState(() => _loop = next);
                    if (!next) {
                      _loopSender.stop();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('循环发送', style: BlueTextStyles.caption(context)),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _loopMsController,
                  keyboardType: TextInputType.number,
                  style: BlueTheme.mono(context, fontSize: 12),
                  decoration: const InputDecoration(hintText: 'ms', isDense: true),
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
            ],
          ),
          const SizedBox(height: 8),
          BluePrimaryButton(label: 'WRITE', busy: _busy, onPressed: () => unawaited(_write())),
        ] else if (widget.expanded)
          const Spacer(),
      ],
    );

    if (widget.expanded) {
      return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: body);
    }

    return Padding(padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset), child: body);
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
        onTap: () => setState(() => _hexMode = hex),
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
