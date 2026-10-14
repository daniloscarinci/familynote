import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/features/notes/note_editor_screen.dart';

void main() {
  testWidgets('autosaves typed text and shows Salvo', (t) async {
    final repo = FakeNoteRepository();
    await t.pumpWidget(MaterialApp(theme: buildTheme(), home: NoteEditorScreen(notes: repo)));
    await t.enterText(find.widgetWithText(TextField, 'Escreva aqui'), 'Comprar pão');
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    final notes = await repo.recent();
    expect(notes.length, 1);
    expect(notes.single.body, 'Comprar pão');
    expect(t.widget<Text>(find.byKey(const Key('save-status'))).data, 'Salvo');
  });
}
