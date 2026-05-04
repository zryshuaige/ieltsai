import 'dart:async';

class Debouncer {
  Timer? _timer;

  void run(Duration duration, FutureOr<void> Function() task) {
    _timer?.cancel();
    _timer = Timer(duration, () {
      task();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
