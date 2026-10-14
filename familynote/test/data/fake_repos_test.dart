import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/data/fake_repos.dart';

void main() {
  test('created note appears in recent list, newest first', () async {
    final repo = FakeNoteRepository();
    await repo.create(title: 'A', body: '');
    await repo.create(title: 'B', body: '');
    final recent = await repo.recent();
    expect(recent.map((n) => n.title), ['B', 'A']);
  });

  test('search matches title and body, ignoring case', () async {
    final repo = FakeNoteRepository();
    await repo.create(title: 'Mercado', body: 'leite e pão');
    expect((await repo.search('LEITE')).length, 1);
    expect((await repo.search('banana')).length, 0);
  });

  test('deleted notes leave recent and land in trash', () async {
    final repo = FakeNoteRepository();
    final n = await repo.create(title: 'X', body: '');
    await repo.softDelete(n.id);
    expect(await repo.recent(), isEmpty);
    expect((await repo.trash()).single.id, n.id);
  });
}
