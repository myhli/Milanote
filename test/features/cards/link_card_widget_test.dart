import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/link_card.dart';
import 'package:localboard/features/cards/widgets/link_card_widget.dart';

void main() {
  group('LinkCardWidget Tests (ADV-02)', () {
    testWidgets('renders domain badge, title, description, and link action icons', (tester) async {
      final now = DateTime.now();
      final card = LinkCard(
        id: 'test-link',
        x: 0,
        y: 0,
        width: 300,
        height: 260,
        url: 'https://artstation.com/artwork/demo',
        title: 'Konsep Pedang Legendaris',
        description: 'Desain ornamen emas dan bilah kristal.',
        siteName: 'artstation.com',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 260,
                child: LinkCardWidget(
                  card: card,
                  boardId: 'test-board',
                  isSelected: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('artstation.com'), findsOneWidget);
      expect(find.text('Konsep Pedang Legendaris'), findsOneWidget);
      expect(find.text('Desain ornamen emas dan bilah kristal.'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });
  });
}
