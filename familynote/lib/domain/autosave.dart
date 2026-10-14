import 'dart:async';
import '../core/status.dart';

class Autosaver {
  Autosaver({required this.save, this.delay = const Duration(milliseconds: 800)});

  final Future<void> Function(String text) save;
  final Duration delay;
  final _controller = StreamController<SaveStatus>.broadcast();
  Timer? _timer;
  String? unsaved;

  Stream<SaveStatus> get status => _controller.stream;

  void onChanged(String text) {
    unsaved = text;
    _timer?.cancel();
    _timer = Timer(delay, _flush);
  }

  Future<void> _flush() async {
    final text = unsaved;
    if (text == null) return;
    _controller.add(SaveStatus.saving);
    try {
      await save(text);
      if (unsaved == text) unsaved = null;
      _controller.add(SaveStatus.saved);
    } catch (_) {
      _controller.add(SaveStatus.pending);
    }
  }

  /// Call on app resume or connectivity change to retry kept text.
  Future<void> retry() => _flush();

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
