import 'dart:async';
import 'dart:ui';

class Debounce {
  final Duration delay;
  Timer? _timer;

  Debounce({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
