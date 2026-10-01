import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/core/utils/bounding_box_calculator.dart';
import 'package:localboard/features/cards/models/note_card.dart';

void main() {
  group('BoundingBoxCalculator Tests (EXP-01)', () {
    NoteCard makeCard(String id, double x, double y, double w, double h) {
      return NoteCard(
        id: id,
        x: x,
        y: y,
        width: w,
        height: h,
        zIndex: 1,
        title: id,
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('empty cards returns default min dimensions centered at origin', () {
      final rect = BoundingBoxCalculator.calculate(
        cards: const [],
        minWidth: 800,
        minHeight: 600,
      );

      expect(rect.width, equals(800));
      expect(rect.height, equals(600));
      expect(rect.left, equals(0));
      expect(rect.top, equals(0));
    });

    test('single card applies padding around its dimensions', () {
      final card = makeCard('c1', 100, 100, 800, 600);
      final rect = BoundingBoxCalculator.calculate(
        cards: [card],
        padding: 50,
      );

      expect(rect.left, equals(50));
      expect(rect.top, equals(50));
      expect(rect.right, equals(950));
      expect(rect.bottom, equals(750));
      expect(rect.width, equals(900));
      expect(rect.height, equals(700));
    });

    test('multiple cards encloses extents accurately with padding', () {
      final card1 = makeCard('c1', -100, -50, 200, 100);
      final card2 = makeCard('c2', 500, 400, 300, 200);

      final rect = BoundingBoxCalculator.calculate(
        cards: [card1, card2],
        padding: 40,
      );

      // minX = -100, maxX = 800 -> left = -140, right = 840, width = 980
      // minY = -50, maxY = 600 -> top = -90, bottom = 640, height = 730
      expect(rect.left, equals(-140));
      expect(rect.top, equals(-90));
      expect(rect.right, equals(840));
      expect(rect.bottom, equals(640));
      expect(rect.width, equals(980));
      expect(rect.height, equals(730));
    });

    test('enforces minWidth and minHeight on small contents', () {
      final smallCard = makeCard('c1', 0, 0, 50, 50);
      final rect = BoundingBoxCalculator.calculate(
        cards: [smallCard],
        padding: 10,
        minWidth: 400,
        minHeight: 300,
      );

      expect(rect.width, equals(400));
      expect(rect.height, equals(300));
    });
  });
}
