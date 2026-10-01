import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/export_import/pdf_export/pdf_export_dialog.dart';

void main() {
  group('PdfExportDialog Tests (PKG-03 & US-012)', () {
    testWidgets('renders format options, paper size, orientation, and action buttons', (tester) async {
      final now = DateTime.now();
      final cards = [
        NoteCard(
          id: 'n1',
          x: 0,
          y: 0,
          title: 'Catatan Referensi',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  PdfExportDialog.show(
                    context,
                    boardTitle: 'Papan Eksperimen',
                    boardId: 'test_board_1',
                    cards: cards,
                    arrows: const [],
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Ekspor Dokumen PDF'), findsOneWidget);
      expect(find.text('Poster 1 Lembar'), findsOneWidget);
      expect(find.text('Multi-Halaman'), findsOneWidget);
      expect(find.text('Kertas A4 (Standar)'), findsOneWidget);
      expect(find.text('Kertas A3 (Poster Besar)'), findsOneWidget);
      expect(find.text('Lanskap (Mendatar)'), findsOneWidget);
      expect(find.text('Potret (Tegak)'), findsOneWidget);
      expect(find.text('Simpan Berkas PDF'), findsOneWidget);
    });
  });
}
