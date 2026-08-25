import 'dart:async';

import 'package:blue_app/core/app_log.dart';
import 'package:blue_app/pages/blue_scope.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_device_pane.dart';
import 'package:flutter/material.dart';

/// 手机窄屏：GATT 设备详情路由。
class BlueGattDevicePage extends StatelessWidget {
  const BlueGattDevicePage({super.key});

  Future<void> _leaveDetail(BuildContext context, BlueScope scope) async {
    AppLog.info('[UI] 离开详情');
    await scope.session.disconnect();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = BlueScope.of(context);
    final palette = BlueTheme.of(context);
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
          title: const Text('设备详情'),
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
        body: BlueDevicePane(session: scope.session, lightMode: scope.lightMode),
      ),
    );
  }
}
