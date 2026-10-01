import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/export_import/image_export/export_preview_dialog.dart';

void main() {
  testWidgets('ExportPreviewDialog renders preview and resolution controls (EXP-03)',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final cards = [
      NoteCard(
        id: 'n1',
        x: 0,
        y: 0,
        width: 200,
        height: 150,
        zIndex: 1,
        title: 'Preview Card',
        content: 'Some design notes',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExportPreviewDialog(
            cards: cards,
            arrows: const [],
            boardTitle: 'Test Studio Board',
            isDark: true,
          ),
        ),
      ),
    );

    // Pump until rasterization completes and progress indicator disappears
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pump();

    // Verify dialog header
    expect(find.text('Ekspor Gambar Resolusi Tinggi (PNG)'), findsOneWidget);

    // Verify resolution options
    expect(find.text('1x (Standar)'), findsOneWidget);
    expect(find.text('2x (Retina)'), findsOneWidget);
    expect(find.text('3x (Ultra HD)'), findsOneWidget);

    // Verify action button
    expect(find.text('Simpan Gambar (PNG)'), findsOneWidget);

    // Switch resolution
    await tester.tap(find.text('3x (Ultra HD)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
