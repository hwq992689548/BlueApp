import 'dart:async';

import 'package:blue_app/core/app_log.dart';
import 'package:blue_app/session/fbp_gatt_session.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/theme/blue_layout_styles.dart';
import 'package:blue_app/theme/blue_text_styles.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_characteristic_panel.dart';
import 'package:blue_app/widgets/blue_characteristic_sheet.dart';
import 'package:blue_app/widgets/blue_console_panel.dart';
import 'package:blue_app/widgets/blue_outline_button.dart';
import 'package:blue_app/widgets/blue_property_chips.dart';
import 'package:blue_app/widgets/blue_rssi_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 设备详情布局密度。
enum BlueDevicePaneLayout {
  /// 手机：纵向服务树 + 底部 CONSOLE；特征走半屏。
  phone,

  /// 宽屏：顶栏 + 服务树 | 特征面板（CONSOLE 由壳层侧栏承载）。
  wide,
}

/// 已连接设备详情面板。
class BlueDevicePane extends StatefulWidget {
  const BlueDevicePane({super.key, required this.session, required this.lightMode, this.layout = BlueDevicePaneLayout.phone});

  final LinkSession session;
  final bool lightMode;
  final BlueDevicePaneLayout layout;

  @override
  State<BlueDevicePane> createState() => _BlueDevicePaneState();
}

class _BlueDevicePaneState extends State<BlueDevicePane> {
  final Set<String> _expandedServices = {};
  BluetoothCharacteristic? _selectedCharacteristic;
  bool _consoleExpanded = true;
  StreamSubscription<bool>? _connectionSub;

  bool get _wide => widget.layout == BlueDevicePaneLayout.wide;

  BlueLayoutStyles get _styles => _wide ? BlueLayoutStyles.wide : BlueLayoutStyles.phone;

  FbpGattSession? get _gatt {
    final session = widget.session;
    return session is FbpGattSession ? session : null;
  }

  @override
  void initState() {
    super.initState();
    _connectionSub = widget.session.isConnected$.listen((connected) {
      if (!connected && mounted) {
        setState(() {
          _expandedServices.clear();
          _selectedCharacteristic = null;
        });
      }
    });
  }

  @override
  void dispose() {
    unawaited(_connectionSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.session.isConnected$,
      initialData: false,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        if (!connected) {
          return _buildPlaceholder(context);
        }
        if (_gatt == null) {
          return _buildPlaceholder(context);
        }
        if (_wide) {
          return _buildWideBody(context);
        }
        return _buildPhoneBody(context);
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_searching, size: styles.devicePlaceholderIconSize, color: palette.textMuted),
          SizedBox(height: styles.devicePlaceholderIconGap),
          Text(
            _wide ? '在左侧选择并连接设备' : '连接设备后在此查看服务与控制台',
            textAlign: TextAlign.center,
            style: BlueTextStyles.caption(context).copyWith(color: palette.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWideBody(BuildContext context) {
    final palette = BlueTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWideHeader(context),
        Divider(height: 1, color: palette.border),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _buildServicesColumn(context)),
              VerticalDivider(width: 1, color: palette.border),
              Expanded(flex: 6, child: _buildWideCharacteristicPane(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedMeta({required Widget Function(ScanItem? item, int? rssi, int? mtu) builder}) {
    final gatt = _gatt;
    return StreamBuilder<int?>(
      stream: gatt?.rssi$,
      builder: (context, rssiSnap) {
        return StreamBuilder<int?>(
          stream: gatt?.mtu$,
          builder: (context, mtuSnap) {
            return builder(widget.session.connectedItem, rssiSnap.data, mtuSnap.data);
          },
        );
      },
    );
  }

  Widget _buildWideHeader(BuildContext context) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    final gatt = _gatt;
    return ColoredBox(
      color: palette.panel,
      child: Padding(
        padding: styles.deviceTopWidePadding,
        child: _buildConnectedMeta(
          builder: (item, rssi, mtu) {
            final resolvedName = _resolveName(item);
            return Row(
              children: [
                Icon(Icons.bluetooth_connected, size: 18, color: palette.accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(resolvedName, style: BlueTextStyles.deviceName(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    item?.id ?? '',
                    style: BlueTheme.mono(context, fontSize: styles.deviceRemoteIdFontSize, color: palette.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                if (rssi != null) ...[
                  BlueRssiBars(rssi: rssi),
                  const SizedBox(width: 6),
                  Text('$rssi dBm', style: BlueTextStyles.caption(context)),
                  const SizedBox(width: 14),
                ],
                Text('MTU ${mtu ?? '—'}', style: BlueTextStyles.caption(context)),
                const SizedBox(width: 12),
                if (gatt != null) BlueOutlineButton(label: 'MTU 512', onPressed: () => unawaited(gatt.requestMtu(512))),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => unawaited(widget.session.disconnect()),
                  child: Text(
                    '断开',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.danger),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideCharacteristicPane(BuildContext context) {
    final palette = BlueTheme.of(context);
    final gatt = _gatt;
    final characteristic = _selectedCharacteristic;
    if (characteristic == null || gatt == null) {
      return ColoredBox(
        color: palette.canvas,
        child: Center(
          child: Text('选择特征以读写', style: BlueTextStyles.caption(context).copyWith(color: palette.textMuted)),
        ),
      );
    }
    return ColoredBox(
      color: palette.canvas,
      child: BlueCharacteristicPanel(key: ValueKey(characteristic.uuid.str), session: gatt, characteristic: characteristic, expanded: true),
    );
  }

  Widget _buildPhoneBody(BuildContext context) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    final gatt = _gatt;
    return Column(
      children: [
        Padding(
          padding: styles.deviceTopOuterPadding,
          child: _buildConnectedMeta(
            builder: (item, rssi, mtu) {
              final resolvedName = _resolveName(item);
              return Container(
                padding: styles.deviceTopInnerPadding,
                decoration: BlueTheme.panelDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONNECTED', style: BlueTextStyles.section(context)),
                    SizedBox(height: styles.deviceTopTitleGap),
                    Text(resolvedName, style: BlueTextStyles.deviceName(context)),
                    Text(
                      item?.id ?? '',
                      style: BlueTheme.mono(context, fontSize: styles.deviceRemoteIdFontSize, color: palette.textSecondary),
                    ),
                    SizedBox(height: styles.deviceTopMetaGap),
                    Row(
                      children: [
                        if (rssi != null) ...[
                          BlueRssiBars(rssi: rssi),
                          const SizedBox(width: 8),
                          Text('$rssi dBm', style: BlueTextStyles.caption(context)),
                          const SizedBox(width: 12),
                        ],
                        Text('MTU ${mtu ?? '—'}', style: BlueTextStyles.caption(context)),
                        const Spacer(),
                        if (gatt != null) BlueOutlineButton(label: 'MTU 512', onPressed: () => unawaited(gatt.requestMtu(512))),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(flex: _consoleExpanded ? 3 : 5, child: _buildServicesColumn(context)),
        BlueConsolePanel(
          session: widget.session,
          expanded: _consoleExpanded,
          onToggleExpanded: () => setState(() => _consoleExpanded = !_consoleExpanded),
        ),
      ],
    );
  }

  Widget _buildServicesColumn(BuildContext context) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    final gatt = _gatt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: styles.serviceSectionPadding,
          child: Row(
            children: [
              Text('SERVICES', style: BlueTextStyles.section(context)),
              const Spacer(),
              Text(styles.serviceSectionHint, style: BlueTextStyles.caption(context).copyWith(color: palette.textMuted)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BluetoothService>>(
            stream: gatt?.services$,
            initialData: const [],
            builder: (context, snapshot) {
              final services = snapshot.data ?? const [];
              if (services.isEmpty) {
                return Center(child: Text('发现服务中…', style: BlueTextStyles.caption(context)));
              }
              return ListView.builder(
                padding: styles.serviceListPadding,
                itemCount: services.length,
                itemBuilder: (context, index) => _buildServiceCard(context, services[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, BluetoothService service) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    final key = service.uuid.str;
    final expanded = _expandedServices.contains(key);
    final radius = BorderRadius.circular(styles.serviceCardRadius);
    return Padding(
      padding: EdgeInsets.only(bottom: styles.serviceCardGap),
      child: Material(
        color: palette.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedServices.remove(key);
                  } else {
                    _expandedServices.add(key);
                  }
                });
              },
              child: Padding(
                padding: styles.serviceHeaderPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SERVICE', style: BlueTextStyles.section(context).copyWith(fontSize: 10, letterSpacing: 0.6)),
                          const SizedBox(height: 4),
                          Text(
                            service.uuid.str,
                            style: BlueTheme.mono(context, fontSize: styles.serviceUuidFontSize, fontWeight: FontWeight.w600),
                            maxLines: styles.serviceUuidMaxLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text('${service.characteristics.length} characteristics', style: BlueTextStyles.caption(context)),
                        ],
                      ),
                    ),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more, color: palette.textSecondary, size: styles.serviceExpandIconSize),
                  ],
                ),
              ),
            ),
            if (expanded)
              ColoredBox(
                color: palette.canvas.withValues(alpha: widget.lightMode ? 0.55 : 0.35),
                child: Column(children: [for (final characteristic in service.characteristics) _buildCharacteristicTile(context, characteristic)]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicTile(BuildContext context, BluetoothCharacteristic characteristic) {
    final palette = BlueTheme.of(context);
    final styles = _styles;
    final gatt = _gatt;
    final id = characteristic.uuid.str;
    final selected = _selectedCharacteristic?.uuid.str == id;
    return Material(
      color: selected ? palette.accent.withValues(alpha: widget.lightMode ? 0.12 : 0.16) : Colors.transparent,
      child: InkWell(
        onTap: () async {
          AppLog.info('[UI] 打开特征 $id');
          if (_wide) {
            setState(() => _selectedCharacteristic = characteristic);
            return;
          }
          if (gatt == null) {
            return;
          }
          setState(() => _selectedCharacteristic = characteristic);
          await BlueCharacteristicSheetSupport.show(context: context, session: gatt, characteristic: characteristic);
          if (mounted) {
            setState(() => _selectedCharacteristic = null);
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: palette.border.withValues(alpha: 0.7)),
              left: BorderSide(color: selected ? palette.accent : palette.border, width: selected ? 3 : 1),
            ),
          ),
          child: Padding(
            padding: styles.characteristicTilePadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id,
                        style: BlueTheme.mono(context, fontSize: styles.characteristicTileUuidFontSize, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: styles.characteristicUuidToChipsGap),
                      BluePropertyChips(properties: characteristic.properties, compact: styles.characteristicChipsCompact),
                    ],
                  ),
                ),
                SizedBox(width: styles.characteristicTileTrailingGap),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    _wide ? (selected ? Icons.edit_note : Icons.chevron_right) : Icons.chevron_right,
                    size: 18,
                    color: selected ? palette.accent : palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resolveName(ScanItem? item) {
    if (item == null) {
      return '—';
    }
    final name = item.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return item.id;
  }
}
