import 'dart:async';

import 'package:blue_app/core/app_names.dart';
import 'package:blue_app/pages/blue_scope.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_scan_pane.dart';
import 'package:blue_app/widgets/blue_settings_sheet.dart';
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
  void _openSettings() {
    final scope = BlueScope.of(context);
    unawaited(
      BlueSettingsSheet.show(
        context: context,
        useFeasy: () => scope.host?.useFeasy ?? false,
        onUseFeasyChanged: scope.onUseFeasyChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = BlueScope.of(context);
    final palette = BlueTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppNames.zh),
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
        ],
      ),
      body: BlueScanPane(
        session: scope.session,
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
