import 'dart:async';

import 'package:blue_app/pages/blue_scope.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_scan_pane.dart';
import 'package:flutter/material.dart';

/// 手机窄屏：扫描列表路由。
class BlueScanPage extends StatefulWidget {
  const BlueScanPage({super.key});

  static const deviceRoute = '/blue/device';
  static const serialRoute = '/blue/serial';

  @override
  State<BlueScanPage> createState() => _BlueScanPageState();
}

class _BlueScanPageState extends State<BlueScanPage> {
  final GlobalKey<BlueScanPaneState> _paneKey = GlobalKey<BlueScanPaneState>();

  void _openSettings() {
    final scope = BlueScope.of(context);
    final host = scope.host;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SwitchListTile(
                title: const Text('使用 Feasy 链路'),
                value: host?.useFeasy ?? false,
                onChanged: scope.onUseFeasyChanged == null
                    ? null
                    : (value) async {
                        try {
                          await scope.onUseFeasyChanged!(value);
                        } catch (_) {
                          // Home already toasts and keeps the switch off.
                        }
                        setSheetState(() {});
                      },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = BlueScope.of(context);
    final palette = BlueTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('BlueApp'),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: _openSettings,
            icon: Icon(Icons.settings_outlined, color: palette.textSecondary),
          ),
          IconButton(
            tooltip: scope.lightMode ? '夜间模式' : '白日模式',
            onPressed: scope.onLightModeToggle,
            icon: Icon(scope.lightMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: palette.textSecondary),
          ),
          StreamBuilder<bool>(
            stream: scope.session.isScanning$,
            initialData: false,
            builder: (context, snapshot) {
              final scanning = snapshot.data ?? false;
              return TextButton(
                onPressed: () => unawaited(_paneKey.currentState?.toggleScan() ?? Future<void>.value()),
                child: Text(
                  scanning ? '停止' : '扫描',
                  style: TextStyle(color: scanning ? palette.warn : palette.accent, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
        ],
      ),
      body: BlueScanPane(
        key: _paneKey,
        session: scope.session,
        keywordController: scope.keywordController,
        hideInvalid: scope.hideInvalid,
        onHideInvalidChanged: scope.onHideInvalidChanged,
        connectingId: scope.connectingId,
        onConnectingIdChanged: scope.onConnectingIdChanged,
        showClassicFilter: scope.showClassicFilter,
        radioFilter: scope.radioFilter,
        onRadioFilterChanged: scope.onRadioFilterChanged,
        tryTurnOnIfOff: scope.host?.classicSupported() ?? false,
        onConnectSucceeded: () {
          if (!mounted) {
            return;
          }
          final route = scope.session.hasGattTree ? BlueScanPage.deviceRoute : BlueScanPage.serialRoute;
          unawaited(Navigator.of(context).pushNamed(route));
        },
      ),
    );
  }
}
