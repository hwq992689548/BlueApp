import 'dart:async';

import 'package:blue_app/core/app_log.dart';
import 'package:blue_app/core/scan_filter.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/theme/blue_layout_styles.dart';
import 'package:blue_app/theme/blue_text_styles.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_primary_button.dart';
import 'package:blue_app/widgets/blue_rssi_bars.dart';
import 'package:flutter/material.dart';

/// 扫描列表面板。
class BlueScanPane extends StatefulWidget {
  const BlueScanPane({
    super.key,
    required this.session,
    required this.keywordController,
    required this.hideInvalid,
    required this.onHideInvalidChanged,
    required this.connectingId,
    required this.onConnectingIdChanged,
    required this.onConnectSucceeded,
    this.compact = false,
  });

  final LinkSession session;
  final TextEditingController keywordController;
  final bool hideInvalid;
  final ValueChanged<bool> onHideInvalidChanged;
  final String? connectingId;
  final ValueChanged<String?> onConnectingIdChanged;
  final VoidCallback onConnectSucceeded;
  final bool compact;

  @override
  State<BlueScanPane> createState() => _BlueScanPaneState();
}

class _BlueScanPaneState extends State<BlueScanPane> {
  String _keyword = '';

  BlueLayoutStyles get _styles => widget.compact ? BlueLayoutStyles.wide : BlueLayoutStyles.phone;

  @override
  void initState() {
    super.initState();
    _keyword = widget.keywordController.text;
    widget.keywordController.addListener(_onKeywordChanged);
  }

  @override
  void dispose() {
    widget.keywordController.removeListener(_onKeywordChanged);
    super.dispose();
  }

  void _onKeywordChanged() {
    setState(() => _keyword = widget.keywordController.text);
  }

  Future<void> _connect(ScanItem item) async {
    widget.onConnectingIdChanged(item.id);
    AppLog.info('[UI] 点击连接 id=${item.id}');
    try {
      await widget.session.connect(item);
      widget.onConnectSucceeded();
    } catch (e) {
      _toast('连接失败: $e');
    } finally {
      widget.onConnectingIdChanged(null);
    }
  }

  Future<void> _toggleScan(bool scanning) async {
    try {
      if (scanning) {
        await widget.session.stopScan();
      } else {
        final on = await widget.session.isBluetoothOn();
        if (!on) {
          _toast('请先打开蓝牙');
          return;
        }
        await widget.session.startScan();
      }
    } catch (e) {
      _toast('$e');
    }
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayName(ScanItem item) {
    final name = item.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return '(无名称)';
  }

  String _kindLabel(ScanKind kind) {
    return switch (kind) {
      ScanKind.ble => 'BLE',
      ScanKind.classic => 'Classic',
      ScanKind.feasy => 'Feasy',
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.compact) _buildCompactToolbar(context) else _buildPhoneFilterCard(context),
        Expanded(
          child: StreamBuilder<List<ScanItem>>(
            stream: widget.session.scanResults$,
            initialData: const [],
            builder: (context, snapshot) {
              final results = snapshot.data ?? const [];
              final filtered = results.where((item) {
                return ScanFilter.shouldShow(
                  keyword: _keyword,
                  hideInvalid: widget.hideInvalid,
                  advName: item.name,
                  platformName: item.name,
                  remoteId: item.id,
                  connectable: item.connectable,
                );
              }).toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    styles.scanEmptyMessage,
                    textAlign: TextAlign.center,
                    style: BlueTextStyles.caption(context).copyWith(color: palette.textMuted, height: 1.5),
                  ),
                );
              }
              return StreamBuilder<bool>(
                stream: widget.session.isConnected$,
                initialData: false,
                builder: (context, _) {
                  final connectedId = widget.session.connectedItem?.id;
                  return ListView.separated(
                    padding: styles.scanListPadding,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => SizedBox(height: styles.scanListSeparator),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      if (widget.compact) {
                        return _buildCompactTile(context, item, selected: connectedId == item.id);
                      }
                      return _buildPhoneTile(context, item);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactToolbar(BuildContext context) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    return Container(
      padding: styles.scanToolbarPadding,
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('DEVICES', style: BlueTextStyles.section(context)),
              SizedBox(width: styles.scanToolbarTitleGap),
              StreamBuilder<List<ScanItem>>(
                stream: widget.session.scanResults$,
                initialData: const [],
                builder: (context, snapshot) {
                  final results = snapshot.data ?? const [];
                  return Text('${results.length}', style: BlueTextStyles.caption(context).copyWith(color: palette.textMuted));
                },
              ),
              const Spacer(),
              StreamBuilder<bool>(
                stream: widget.session.isScanning$,
                initialData: false,
                builder: (context, snapshot) {
                  final scanning = snapshot.data ?? false;
                  return TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => unawaited(_toggleScan(scanning)),
                    child: Text(
                      scanning ? '停止' : '扫描',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scanning ? palette.warn : palette.accent),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: styles.scanToolbarFieldGap),
          TextField(
            controller: widget.keywordController,
            style: TextStyle(color: palette.textPrimary, fontSize: styles.scanKeywordFontSize),
            decoration: InputDecoration(
              isDense: true,
              hintText: styles.scanKeywordHint,
              prefixIcon: Icon(Icons.search, size: styles.scanSearchIconSize, color: palette.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
          SizedBox(height: styles.scanFilterFieldGap),
          _buildHideInvalidRow(context, styles: styles),
        ],
      ),
    );
  }

  Widget _buildPhoneFilterCard(BuildContext context) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    return Padding(
      padding: styles.scanFilterOuterPadding,
      child: Container(
        padding: styles.scanFilterInnerPadding,
        decoration: BlueTheme.panelDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SCANNER', style: BlueTextStyles.section(context)),
            SizedBox(height: styles.scanFilterTitleGap),
            Text('BLE GATT 扫描 · 列表右侧「连接」直连', style: BlueTextStyles.caption(context).copyWith(height: 1.35)),
            SizedBox(height: styles.scanFilterDescGap),
            TextField(
              controller: widget.keywordController,
              style: TextStyle(color: palette.textPrimary, fontSize: styles.scanKeywordFontSize),
              decoration: InputDecoration(
                hintText: styles.scanKeywordHint,
                prefixIcon: Icon(Icons.search, size: styles.scanSearchIconSize, color: palette.textMuted),
              ),
            ),
            SizedBox(height: styles.scanFilterFieldGap),
            _buildHideInvalidRow(context, styles: styles),
          ],
        ),
      ),
    );
  }

  Widget _buildHideInvalidRow(BuildContext context, {required BlueLayoutStyles styles}) {
    return Row(
      children: [
        SizedBox(
          width: styles.scanCheckboxSize,
          height: styles.scanCheckboxSize,
          child: Checkbox(
            value: widget.hideInvalid,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: widget.compact ? VisualDensity.compact : VisualDensity.standard,
            onChanged: (value) {
              final next = value ?? true;
              AppLog.info('[UI] hideInvalid=$next');
              widget.onHideInvalidChanged(next);
            },
          ),
        ),
        SizedBox(width: styles.scanCheckboxGap),
        Expanded(child: Text(styles.scanHideInvalidLabel, style: BlueTextStyles.caption(context))),
      ],
    );
  }

  Widget _buildCompactTile(BuildContext context, ScanItem item, {required bool selected}) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    final id = item.id;
    final busy = widget.connectingId == id;
    final radius = BorderRadius.circular(styles.scanTileRadius);
    return Material(
      color: selected ? palette.accent.withValues(alpha: 0.14) : palette.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: selected ? palette.accent : palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.connectable && widget.connectingId == null ? () => unawaited(_connect(item)) : null,
        child: Padding(
          padding: styles.scanTilePadding,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(item),
                      style: BlueTextStyles.deviceName(context).copyWith(fontSize: styles.scanTileNameFontSize),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: styles.scanTileNameToIdGap),
                    Text(
                      id,
                      style: BlueTheme.mono(context, fontSize: styles.scanTileIdFontSize, color: palette.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: styles.scanTileIdToMetaGap),
                    Row(
                      children: [
                        BlueRssiBars(rssi: item.rssi),
                        SizedBox(width: styles.scanTileRssiBarsGap),
                        Text('${item.rssi}', style: BlueTextStyles.caption(context).copyWith(fontSize: styles.scanTileRssiFontSize)),
                        SizedBox(width: styles.scanTileRssiToStatusGap),
                        Text(
                          _kindLabel(item.kind),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.accentInfo),
                        ),
                        if (!item.connectable) ...[
                          const SizedBox(width: 8),
                          Text(
                            'BC',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.warn),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: styles.scanTileTrailingGap),
              if (busy)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else if (selected)
                Icon(Icons.link, size: 18, color: palette.accent)
              else
                Icon(Icons.chevron_right, size: 18, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneTile(BuildContext context, ScanItem item) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    final id = item.id;
    final busy = widget.connectingId == id;
    return Container(
      decoration: BlueTheme.panelDecoration(context, color: palette.elevated),
      padding: styles.scanTilePadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(item),
                  style: BlueTextStyles.deviceName(context).copyWith(fontSize: styles.scanTileNameFontSize),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: styles.scanTileNameToIdGap),
                Text(
                  id,
                  style: BlueTheme.mono(context, fontSize: styles.scanTileIdFontSize, color: palette.textSecondary),
                ),
                SizedBox(height: styles.scanTileIdToMetaGap),
                Row(
                  children: [
                    BlueRssiBars(rssi: item.rssi),
                    SizedBox(width: styles.scanTileRssiBarsGap),
                    Text('${item.rssi} dBm', style: BlueTextStyles.caption(context).copyWith(fontSize: styles.scanTileRssiFontSize)),
                    SizedBox(width: styles.scanTileRssiToStatusGap),
                    Text(
                      _kindLabel(item.kind),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: palette.accentInfo),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.connectable ? 'CONNECTABLE' : 'BROADCAST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: item.connectable ? palette.accent : palette.warn,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: styles.scanTileTrailingGap),
          BluePrimaryButton(
            label: '连接',
            busy: busy,
            onPressed: item.connectable && widget.connectingId == null ? () => unawaited(_connect(item)) : null,
          ),
        ],
      ),
    );
  }
}
