import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/subboard_card.dart';
import 'package:localboard/features/cards/widgets/subboard_card_widget.dart';

void main() {
  group('SubBoardCardWidget Tests (ADV-03)', () {
    testWidgets('renders folder icon, title, card count badge, and triggers onOpenSubBoard', (tester) async {
      final now = DateTime.now();
      final card = SubBoardCard(
        id: 'test-subboard',
        x: 0,
        y: 0,
        width: 320,
        height: 200,
        targetBoardId: 'child_board_123',
        title: 'Desain Senjata & Perlengkapan',
        cardCount: 5,
        description: 'Kumpulan referensi tombak dan perisai kuno.',
        createdAt: now,
        updatedAt: now,
      );

      bool opened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 200,
                child: SubBoardCardWidget(
                  card: card,
                  isSelected: true,
                  onOpenSubBoard: () => opened = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Desain Senjata & Perlengkapan'), findsOneWidget);
      expect(find.text('5 kartu'), findsOneWidget);
      expect(find.text('Kumpulan referensi tombak dan perisai kuno.'), findsOneWidget);
      expect(find.byIcon(Icons.folder_special_rounded), findsOneWidget);
      expect(find.text('Buka Papan'), findsOneWidget);

      // Trigger double-tap as per US-009
      await tester.tap(find.byType(SubBoardCardWidget));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(SubBoardCardWidget));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });
  });
}
