import 'dart:async';

class LoopSender {
  LoopSender({required this.send, required this.interval});

  final Future<void> Function(List<int> bytes) send;
  final Duration Function() interval;

  Timer? _timer;
  List<int> _bytes = const [];
  bool get isRunning => _timer != null;

  void start(List<int> bytes) {
    stop();
    _bytes = List<int>.from(bytes);
    unawaited(send(_bytes));
    _timer = Timer(interval(), _tick);
  }

  void _tick() {
    if (_timer == null) {
      return;
    }
    unawaited(send(_bytes));
    _timer = Timer(interval(), _tick);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
