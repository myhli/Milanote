import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/base_card.dart';
import 'package:localboard/features/cards/models/link_card.dart';

void main() {
  group('LinkCard Model Tests (ADV-02)', () {
    test('instantiation, copyWith, moveTo, resizeTo, withZIndex maintain immutability', () {
      final now = DateTime.now();
      final card = LinkCard(
        id: 'link-1',
        x: 100,
        y: 200,
        width: 300,
        height: 260,
        zIndex: 5,
        url: 'https://pinterest.com/pin/123',
        title: 'Referensi Pencahayaan',
        description: 'Studi pencahayaan dramatis untuk lukisan potret.',
        siteName: 'pinterest.com',
        coverAssetUuid: 'assets/cover-1.png',
        coverImageUrl: 'https://images.pinterest.com/1.jpg',
        colorHex: '#FFFFFF',
        createdAt: now,
        updatedAt: now,
      );

      expect(card.type, CardType.link);
      expect(card.url, 'https://pinterest.com/pin/123');
      expect(card.title, 'Referensi Pencahayaan');
      expect(card.siteName, 'pinterest.com');

      final moved = card.moveTo(350, 450);
      expect(moved.x, 350);
      expect(moved.y, 450);
      expect(card.x, 100); // Original unchanged

      final resized = card.resizeTo(400, 320);
      expect(resized.width, 400);
      expect(resized.height, 320);
      expect(card.width, 300); // Original unchanged

      final reindexed = card.withZIndex(12);
      expect(reindexed.zIndex, 12);
    });

    test('toJson and fromJson roundtrip serialization including BaseCard factory', () {
      final now = DateTime.now();
      final card = LinkCard(
        id: 'link-roundtrip',
        x: 150,
        y: 250,
        width: 320,
        height: 270,
        zIndex: 2,
        url: 'https://youtube.com/watch?v=speedpaint',
        title: 'Tutorial Melukis Cat Minyak',
        description: 'Teknik kuas basah pada basah.',
        siteName: 'youtube.com',
        coverAssetUuid: 'assets/yt-thumb.jpg',
        coverImageUrl: 'https://i.ytimg.com/vi/thumb.jpg',
        colorHex: '#FFFFFF',
        createdAt: now,
        updatedAt: now,
      );

      final jsonMap = card.toJson();
      expect(jsonMap['type'], 'link');
      expect(jsonMap['url'], 'https://youtube.com/watch?v=speedpaint');

      final fromBase = BaseCard.fromJson(jsonMap);
      expect(fromBase, isA<LinkCard>());
      final restored = fromBase as LinkCard;
      expect(restored.id, card.id);
      expect(restored.url, card.url);
      expect(restored.title, card.title);
      expect(restored.description, card.description);
      expect(restored.coverAssetUuid, card.coverAssetUuid);
    });
  });
}
