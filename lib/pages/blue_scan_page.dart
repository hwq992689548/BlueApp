import 'dart:async';

import 'package:blue_app/pages/blue_scope.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_scan_pane.dart';
import 'package:flutter/material.dart';

/// 手机窄屏：扫描列表路由。
class BlueScanPage extends StatefulWidget {
  const BlueScanPage({super.key});

  static const deviceRoute = '/blue/device';

  @override
  State<BlueScanPage> createState() => _BlueScanPageState();
}

class _BlueScanPageState extends State<BlueScanPage> {
  Future<void> _toggleScan(LinkSession session, bool scanning) async {
    try {
      if (scanning) {
        await session.stopScan();
      } else {
        final on = await session.isBluetoothOn();
        if (!on) {
          _toast('请先打开蓝牙');
          return;
        }
        await session.startScan();
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
                onPressed: () => unawaited(_toggleScan(scope.session, scanning)),
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
        session: scope.session,
        keywordController: scope.keywordController,
        hideInvalid: scope.hideInvalid,
        onHideInvalidChanged: scope.onHideInvalidChanged,
        connectingId: scope.connectingId,
        onConnectingIdChanged: scope.onConnectingIdChanged,
        onConnectSucceeded: () {
          if (mounted) {
            unawaited(Navigator.of(context).pushNamed(BlueScanPage.deviceRoute));
          }
        },
      ),
    );
  }
}
