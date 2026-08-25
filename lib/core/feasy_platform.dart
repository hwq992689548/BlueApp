import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class FeasyPlatform {
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get classicSupported => !kIsWeb && Platform.isAndroid;
}
