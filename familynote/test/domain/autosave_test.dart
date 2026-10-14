import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/status.dart';
import 'package:familynote/domain/autosave.dart';

void main() {
  test('debounces rapid edits into one save and reports status', () {
    fakeAsync((async) {
      final saved = <String>[];
      final statuses = <SaveStatus>[];
      final a = Autosaver(
        save: (text) async => saved.add(text),
        delay: const Duration(milliseconds: 800),
      );
      a.status.listen(statuses.add);

      a.onChanged('o');
      a.onChanged('ol');
      a.onChanged('olá');
      async.elapse(const Duration(milliseconds: 900));
      async.flushMicrotasks();

      expect(saved, ['olá']);
      expect(statuses, [SaveStatus.saving, SaveStatus.saved]);
    });
  });

  test('failed save reports pending and keeps text for retry', () {
    fakeAsync((async) {
      final statuses = <SaveStatus>[];
      final a = Autosaver(
        save: (_) async => throw Exception('offline'),
        delay: const Duration(milliseconds: 100),
      );
      a.status.listen(statuses.add);
      a.onChanged('x');
      async.elapse(const Duration(milliseconds: 200));
      async.flushMicrotasks();
      expect(statuses.last, SaveStatus.pending);
      expect(a.unsaved, 'x');
    });
  });
}
