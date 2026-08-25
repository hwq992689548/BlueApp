import 'hex_support.dart';
import 'log_entry.dart';

class LogStore {
  static const maxEntries = 2000;
  final List<LogEntry> _entries = [];
  List<LogEntry> get entries => List.unmodifiable(_entries);

  void append(LogEntry entry) {
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
  }

  void appendInfo(String message) {
    append(LogEntry(at: DateTime.now(), direction: LogDirection.info, hex: '', message: message));
  }

  void appendBytes({required LogDirection direction, required List<int> bytes, String? message}) {
    append(
      LogEntry(
        at: DateTime.now(),
        direction: direction,
        hex: HexSupport.bytesToHex(bytes),
        ascii: HexSupport.bytesToAsciiPreview(bytes),
        message: message,
      ),
    );
  }

  void clear() => _entries.clear();
}
