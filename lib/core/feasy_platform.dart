import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class FeasyPlatform {
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Test-only override; `null` uses the real platform check.
  static bool? debugClassicSupported;

  static bool get classicSupported =>
      debugClassicSupported ?? (!kIsWeb && Platform.isAndroid);
}
