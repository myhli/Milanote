import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/base_card.dart';
import 'package:localboard/features/cards/models/subboard_card.dart';

void main() {
  group('SubBoardCard Model Tests (ADV-03)', () {
    test('instantiation, copyWith, moveTo, resizeTo, withZIndex maintain immutability', () {
      final now = DateTime.now();
      final card = SubBoardCard(
        id: 'subboard-1',
        x: 80,
        y: 120,
        width: 280,
        height: 180,
        zIndex: 3,
        targetBoardId: 'child_board_999',
        title: 'Desain Senjata & Perlengkapan',
        cardCount: 14,
        description: 'Studi pedang dan busur panah karakter.',
        colorHex: '#6366F1',
        createdAt: now,
        updatedAt: now,
      );

      expect(card.type, CardType.subboard);
      expect(card.targetBoardId, 'child_board_999');
      expect(card.title, 'Desain Senjata & Perlengkapan');
      expect(card.cardCount, 14);

      final moved = card.moveTo(200, 300);
      expect(moved.x, 200);
      expect(moved.y, 300);
      expect(card.x, 80);

      final resized = card.resizeTo(340, 220);
      expect(resized.width, 340);
      expect(resized.height, 220);
      expect(card.width, 280);

      final reindexed = card.withZIndex(10);
      expect(reindexed.zIndex, 10);
    });

    test('toJson and fromJson roundtrip serialization including BaseCard factory', () {
      final now = DateTime.now();
      final card = SubBoardCard(
        id: 'subboard-roundtrip',
        x: 50,
        y: 60,
        width: 290,
        height: 190,
        zIndex: 1,
        targetBoardId: 'board_child_xyz',
        title: 'Studi Lingkungan Latar Belakang',
        cardCount: 8,
        description: 'Pemandangan alam dan tata kota abad pertengahan.',
        colorHex: '#10B981',
        createdAt: now,
        updatedAt: now,
      );

      final jsonMap = card.toJson();
      expect(jsonMap['type'], 'subboard');
      expect(jsonMap['targetBoardId'], 'board_child_xyz');

      final fromBase = BaseCard.fromJson(jsonMap);
      expect(fromBase, isA<SubBoardCard>());
      final restored = fromBase as SubBoardCard;
      expect(restored.id, card.id);
      expect(restored.targetBoardId, card.targetBoardId);
      expect(restored.title, card.title);
      expect(restored.cardCount, 8);
      expect(restored.description, card.description);
      expect(restored.colorHex, '#10B981');
    });
  });
}
