import 'dart:async';

import 'package:blue_app/core/app_log.dart';
import 'package:blue_app/core/blue_prefs.dart';
import 'package:blue_app/core/feasy_errors.dart';
import 'package:blue_app/core/feasy_platform.dart';
import 'package:blue_app/pages/blue_gatt_device_page.dart';
import 'package:blue_app/pages/blue_scan_page.dart';
import 'package:blue_app/pages/blue_scope.dart';
import 'package:blue_app/pages/blue_serial_device_page.dart';
import 'package:blue_app/session/classic_spp_session.dart';
import 'package:blue_app/session/fbp_gatt_session.dart';
import 'package:blue_app/session/feasy_link_session.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:blue_app/session/session_host.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_console_panel.dart';
import 'package:blue_app/widgets/blue_device_pane.dart';
import 'package:blue_app/widgets/blue_scan_pane.dart';
import 'package:flutter/material.dart';

/// BlueApp 入口：宽 ≥1000 master–detail，窄屏分路由。
class BlueHomePage extends StatefulWidget {
  const BlueHomePage({super.key, this.host, this.session, this.prefs});

  final SessionHost? host;
  final LinkSession? session;
  final BluePrefs? prefs;

  /// 宽屏断点（三栏：设备 / 服务·特征 / 控制台）。
  static const wideBreakpoint = 1000.0;

  @override
  State<BlueHomePage> createState() => _BlueHomePageState();
}

class _BlueHomePageState extends State<BlueHomePage> {
  SessionHost? _ownedHost;
  SessionHost? _host;
  late LinkSession _session;
  late final BluePrefs _prefs;
  final TextEditingController _keywordController = TextEditingController();
  StreamSubscription<bool>? _connectedSub;

  bool _hideInvalid = true;
  bool _lightMode = false;
  bool _connected = false;
  String? _connectingId;

  bool get _showClassicFilter {
    final host = _host;
    if (host == null) {
      return false;
    }
    return host.classicSupported() && !host.useFeasy;
  }

  @override
  void initState() {
    super.initState();
    AppLog.info('[UI] 打开 BlueApp 首页');
    _prefs = widget.prefs ?? BluePrefs();
    if (widget.session != null) {
      _session = widget.session!;
      _host = widget.host;
    } else if (widget.host != null) {
      _host = widget.host;
      _session = _host!.current;
    } else {
      _ownedHost = SessionHost(
        createGatt: FbpGattSession.new,
        createClassic: ClassicSppSession.new,
        createFeasy: FeasyLinkSession.new,
        feasySupported: () => FeasyPlatform.isSupported,
        classicSupported: () => FeasyPlatform.classicSupported,
      );
      _host = _ownedHost;
      _session = _host!.current;
    }
    _bindConnected(_session);
    unawaited(_loadPrefs());
    _keywordController.addListener(_onKeywordChanged);
  }

  void _bindConnected(LinkSession session) {
    unawaited(_connectedSub?.cancel());
    _session = session;
    _connectedSub = _session.isConnected$.listen((value) {
      if (mounted) {
        setState(() => _connected = value);
      }
    });
  }

  Future<void> _loadPrefs() async {
    final keyword = await _prefs.readKeyword();
    final hideInvalid = await _prefs.readHideInvalid();
    final lightMode = await _prefs.readLight();
    final useFeasy = await _prefs.readUseFeasy();
    if (!mounted) {
      return;
    }
    setState(() {
      _hideInvalid = hideInvalid;
      _lightMode = lightMode;
      _keywordController.text = keyword;
    });
    final host = _host;
    if (useFeasy && host != null && host.feasySupported()) {
      await _applyFeasy(true, persist: false);
    }
  }

  Future<void> _applyFeasy(bool value, {bool persist = true}) async {
    final host = _host;
    if (host == null) {
      return;
    }
    try {
      await host.setUseFeasy(value);
      _bindConnected(host.current);
      if (persist) {
        await _prefs.writeUseFeasy(value);
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (host.useFeasy) {
        try {
          await host.setUseFeasy(false);
        } catch (_) {}
        _bindConnected(host.current);
      }
      _toast(feasySwitchErrorToast(e));
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _setRadioFilter(RadioFilter value) async {
    final host = _host;
    if (host == null) {
      return;
    }
    try {
      await host.setRadioFilter(value);
      _bindConnected(host.current);
      if (mounted) {
        setState(() {});
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

  void _openSettings() {
    final host = _host;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SwitchListTile(
                title: const Text('使用 Feasy 链路'),
                value: host?.useFeasy ?? false,
                onChanged: (value) async {
                  await _applyFeasy(value);
                  setSheetState(() {});
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _devicePage() {
    if (_session.hasGattTree) {
      return const BlueGattDevicePage();
    }
    return const BlueSerialDevicePage();
  }

  @override
  void dispose() {
    AppLog.info('[UI] 关闭 BlueApp 首页');
    unawaited(_connectedSub?.cancel());
    _keywordController.removeListener(_onKeywordChanged);
    _keywordController.dispose();
    if (_ownedHost != null) {
      unawaited(_session.dispose());
    }
    super.dispose();
  }

  void _onKeywordChanged() {
    unawaited(_prefs.writeKeyword(_keywordController.text));
  }

  void _toggleLightMode() {
    final next = !_lightMode;
    AppLog.info('[UI] lightMode=$next');
    setState(() => _lightMode = next);
    unawaited(_prefs.writeLight(next));
  }

  void _onHideInvalidChanged(bool value) {
    setState(() => _hideInvalid = value);
    unawaited(_prefs.writeHideInvalid(value));
  }

  Widget _wrapScope({required Widget child}) {
    return Theme(
      data: BlueTheme.theme(light: _lightMode),
      child: BlueScope(
        session: _session,
        prefs: _prefs,
        lightMode: _lightMode,
        hideInvalid: _hideInvalid,
        keywordController: _keywordController,
        connectingId: _connectingId,
        onLightModeToggle: _toggleLightMode,
        onHideInvalidChanged: _onHideInvalidChanged,
        onKeywordPersist: (value) => unawaited(_prefs.writeKeyword(value)),
        onConnectingIdChanged: (id) => setState(() => _connectingId = id),
        host: _host,
        showClassicFilter: _showClassicFilter,
        radioFilter: _host?.radioFilter ?? RadioFilter.ble,
        onRadioFilterChanged: (value) => unawaited(_setRadioFilter(value)),
        onUseFeasyChanged: (value) => _applyFeasy(value),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= BlueHomePage.wideBreakpoint;
        if (wide) {
          return _wrapScope(child: Builder(builder: _buildWideLayout));
        }
        return _wrapScope(
          child: Navigator(
            key: const ValueKey<String>('blue_phone_nav'),
            onGenerateInitialRoutes: (navigator, initialRoute) {
              final routes = <Route<dynamic>>[
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: '/'),
                  builder: (_) => const BlueScanPage(),
                ),
              ];
              if (_connected) {
                routes.add(
                  MaterialPageRoute<void>(
                    settings: RouteSettings(
                      name: _session.hasGattTree ? BlueScanPage.deviceRoute : BlueScanPage.serialRoute,
                    ),
                    builder: (_) => _devicePage(),
                  ),
                );
              }
              return routes;
            },
            onGenerateRoute: (settings) {
              if (settings.name == BlueScanPage.deviceRoute) {
                return MaterialPageRoute<void>(builder: (_) => const BlueGattDevicePage());
              }
              if (settings.name == BlueScanPage.serialRoute) {
                return MaterialPageRoute<void>(builder: (_) => const BlueSerialDevicePage());
              }
              return MaterialPageRoute<void>(builder: (_) => const BlueScanPage());
            },
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final palette = BlueTheme.of(context);
    final totalWidth = MediaQuery.sizeOf(context).width;
    final scanWidth = (totalWidth * 0.22).clamp(260.0, 320.0);
    final consoleWidth = (totalWidth * 0.27).clamp(280.0, 400.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlueApp'),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: _openSettings,
            icon: Icon(Icons.settings_outlined, color: palette.textSecondary),
          ),
          IconButton(
            tooltip: _lightMode ? '夜间模式' : '白日模式',
            onPressed: _toggleLightMode,
            icon: Icon(_lightMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: palette.textSecondary),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: scanWidth,
            child: ColoredBox(
              color: palette.canvas,
              child: BlueScanPane(
                session: _session,
                keywordController: _keywordController,
                hideInvalid: _hideInvalid,
                onHideInvalidChanged: _onHideInvalidChanged,
                connectingId: _connectingId,
                onConnectingIdChanged: (id) => setState(() => _connectingId = id),
                onConnectSucceeded: () {},
                compact: true,
                showClassicFilter: _showClassicFilter,
                radioFilter: _host?.radioFilter ?? RadioFilter.ble,
                onRadioFilterChanged: (value) => unawaited(_setRadioFilter(value)),
                tryTurnOnIfOff: _host?.classicSupported() ?? false,
              ),
            ),
          ),
          VerticalDivider(width: 1, color: palette.border),
          Expanded(
            child: ColoredBox(
              color: palette.canvas,
              child: BlueDevicePane(session: _session, lightMode: _lightMode, layout: BlueDevicePaneLayout.wide),
            ),
          ),
          VerticalDivider(width: 1, color: palette.border),
          SizedBox(
            width: consoleWidth,
            child: BlueConsolePanel(session: _session, fillsHeight: true),
          ),
        ],
      ),
    );
  }
}
