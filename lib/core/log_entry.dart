enum LogDirection { tx, rx, info }

class LogEntry {
  LogEntry({required this.at, required this.direction, required this.hex, this.ascii, this.message});
  final DateTime at;
  final LogDirection direction;
  final String hex;
  final String? ascii;
  final String? message;
}
