import 'dart:developer' as developer;

/// BlueApp 调试日志（dart:developer，不依赖 x_logger）。
abstract final class AppLog {
  AppLog._();

  static void info(String message) {
    developer.log(message, name: 'BlueApp');
  }

  static void warning(String message) {
    developer.log(message, name: 'BlueApp', level: 900);
  }

  static void error(String message) {
    developer.log(message, name: 'BlueApp', level: 1000);
  }

  static void success(String message) {
    developer.log(message, name: 'BlueApp');
  }
}
