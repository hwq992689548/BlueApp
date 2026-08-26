import 'dart:developer' as developer;

import 'package:blue_app/core/app_names.dart';

/// 蓝宝助手 / BlueStack 调试日志（dart:developer，不依赖 x_logger）。
abstract final class AppLog {
  AppLog._();

  static void info(String message) {
    developer.log(message, name: AppNames.en);
  }

  static void warning(String message) {
    developer.log(message, name: AppNames.en, level: 900);
  }

  static void error(String message) {
    developer.log(message, name: AppNames.en, level: 1000);
  }

  static void success(String message) {
    developer.log(message, name: AppNames.en);
  }
}
