import 'package:blue_app/core/blue_prefs.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:flutter/material.dart';

/// 页面树共享的会话与偏好。
class BlueScope extends InheritedWidget {
  const BlueScope({
    super.key,
    required this.session,
    required this.prefs,
    required this.lightMode,
    required this.hideInvalid,
    required this.keywordController,
    required this.connectingId,
    required this.onLightModeToggle,
    required this.onHideInvalidChanged,
    required this.onKeywordPersist,
    required this.onConnectingIdChanged,
    required super.child,
  });

  final LinkSession session;
  final BluePrefs prefs;
  final bool lightMode;
  final bool hideInvalid;
  final TextEditingController keywordController;
  final String? connectingId;
  final VoidCallback onLightModeToggle;
  final ValueChanged<bool> onHideInvalidChanged;
  final ValueChanged<String> onKeywordPersist;
  final ValueChanged<String?> onConnectingIdChanged;

  static BlueScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BlueScope>();
    if (scope == null) {
      throw FlutterError('BlueScope not found in context');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(BlueScope oldWidget) {
    return session != oldWidget.session ||
        prefs != oldWidget.prefs ||
        lightMode != oldWidget.lightMode ||
        hideInvalid != oldWidget.hideInvalid ||
        keywordController != oldWidget.keywordController ||
        connectingId != oldWidget.connectingId ||
        onLightModeToggle != oldWidget.onLightModeToggle ||
        onHideInvalidChanged != oldWidget.onHideInvalidChanged ||
        onKeywordPersist != oldWidget.onKeywordPersist ||
        onConnectingIdChanged != oldWidget.onConnectingIdChanged;
  }
}
