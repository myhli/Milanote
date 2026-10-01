import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/widgets/note_card_widget.dart';

void main() {
  testWidgets('NoteCardWidget renders title and content with inline editing', (tester) async {
    final note = NoteCard(
      id: 'test-note-1',
      x: 0,
      y: 0,
      title: 'Judul Eksperimen',
      content: 'Isi catatan sketsa',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    String? updatedTitle;
    String? updatedContent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 250,
            child: NoteCardWidget(
              card: note,
              isSelected: true,
              onTitleChanged: (val) => updatedTitle = val,
              onContentChanged: (val) => updatedContent = val,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Judul Eksperimen'), findsOneWidget);
    expect(find.text('Isi catatan sketsa'), findsOneWidget);

    // Edit title
    await tester.enterText(find.byType(TextField).first, 'Judul Baru');
    expect(updatedTitle, equals('Judul Baru'));

    // Edit content
    await tester.enterText(find.byType(TextField).at(1), 'Catatan Tambahan');
    expect(updatedContent, equals('Catatan Tambahan'));
  });

  testWidgets('NoteCardWidget renders checklist mode and toggles items', (tester) async {
    final note = NoteCard(
      id: 'test-note-2',
      x: 0,
      y: 0,
      title: 'Todo List',
      isChecklistMode: true,
      checklists: const [
        ChecklistItem(id: '1', text: 'Beli cat akrilik', isDone: false),
        ChecklistItem(id: '2', text: 'Siapkan kanvas 40x60', isDone: true),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    List<ChecklistItem>? changedItems;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 250,
            child: NoteCardWidget(
              card: note,
              onChecklistsChanged: (val) => changedItems = val,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Beli cat akrilik'), findsOneWidget);
    expect(find.text('Siapkan kanvas 40x60'), findsOneWidget);

    // Toggle first checkbox
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(changedItems, isNotNull);
    expect(changedItems!.first.isDone, isTrue);
  });
}
