import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/base_card.dart';
import 'package:localboard/features/cards/models/connector_arrow.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/widgets/arrow_painter.dart';

void main() {
  testWidgets('ArrowPainter paints curved and orthogonal connectors between cards', (tester) async {
    final now = DateTime.now();
    final card1 = NoteCard(
      id: 'c1',
      x: 50,
      y: 50,
      width: 200,
      height: 150,
      createdAt: now,
      updatedAt: now,
    );
    final card2 = NoteCard(
      id: 'c2',
      x: 350,
      y: 200,
      width: 200,
      height: 150,
      createdAt: now,
      updatedAt: now,
    );

    final cardMap = <String, BaseCard>{
      'c1': card1,
      'c2': card2,
    };

    final arrows = [
      const ConnectorArrow(
        id: 'a1',
        startCardId: 'c1',
        endCardId: 'c2',
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.curved,
        head: ArrowHead.end,
      ),
      const ConnectorArrow(
        id: 'a2',
        startCardId: 'c1',
        endCardId: 'c2',
        startAnchor: CardAnchor.bottom,
        endAnchor: CardAnchor.top,
        style: ArrowStyle.orthogonal,
        head: ArrowHead.both,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(800, 600),
            painter: ArrowPainter(
              arrows: arrows,
              cardMap: cardMap,
              previewStartPoint: const Offset(100, 100),
              previewEndPoint: const Offset(200, 200),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
  });
}
