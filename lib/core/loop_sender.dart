import 'dart:async';

class LoopSender {
  LoopSender({required this.send, required this.interval, this.onError});

  final Future<void> Function(List<int> bytes) send;
  final Duration Function() interval;
  final void Function(Object error, StackTrace stackTrace)? onError;

  Timer? _timer;
  List<int> _bytes = const [];
  bool get isRunning => _timer != null;

  void start(List<int> bytes) {
    stop();
    _bytes = List<int>.from(bytes);
    unawaited(_fire());
    _timer = Timer(interval(), _tick);
  }

  void _tick() {
    if (_timer == null) {
      return;
    }
    unawaited(_fire());
    _timer = Timer(interval(), _tick);
  }

  Future<void> _fire() async {
    try {
      await send(_bytes);
    } catch (e, st) {
      stop();
      onError?.call(e, st);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
