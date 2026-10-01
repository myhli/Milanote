import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/templates/domain/starter_templates.dart';

void main() {
  group('ArtisticStarterTemplates Tests (GAL-02)', () {
    test('contains exactly 4 artistic templates', () {
      expect(ArtisticStarterTemplates.all.length, equals(4));
      final ids = ArtisticStarterTemplates.all.map((t) => t.id).toSet();
      expect(ids, containsAll([
        'character_moodboard',
        'style_and_color_study',
        'storyboard_6_panel',
        'brainstorming_project',
      ]));
    });

    test('findById returns template when ID matches', () {
      final t = ArtisticStarterTemplates.findById('character_moodboard');
      expect(t, isNotNull);
      expect(t!.name, equals('Moodboard Karakter'));

      expect(ArtisticStarterTemplates.findById('non_existent'), isNull);
    });

    test('character_moodboard template builds cards and valid arrows', () {
      final t = ArtisticStarterTemplates.findById('character_moodboard')!;
      final (cards, arrows) = t.builder('board_123');

      expect(cards.length, equals(5));
      expect(arrows.length, equals(2));

      final cardIds = cards.map((c) => c.id).toSet();
      for (final a in arrows) {
        expect(cardIds, contains(a.startCardId));
        expect(cardIds, contains(a.endCardId));
      }
    });

    test('style_and_color_study template builds 8-color swatch card', () {
      final t = ArtisticStarterTemplates.findById('style_and_color_study')!;
      final (cards, arrows) = t.builder('board_style');

      expect(cards.length, equals(5));
      expect(arrows.isNotEmpty, isTrue);

      final colorCard = cards.firstWhere((c) => c.id.contains('swatches'));
      expect(colorCard.width, greaterThanOrEqualTo(400));
    });

    test('storyboard_6_panel template builds 6 frames and sequential arrows', () {
      final t = ArtisticStarterTemplates.findById('storyboard_6_panel')!;
      final (cards, arrows) = t.builder('board_sb');

      expect(cards.length, equals(12)); // 6 images + 6 notes
      expect(arrows.length, equals(5)); // 5 connector arrows
    });

    test('brainstorming_project template builds central idea and 4 radial branches', () {
      final t = ArtisticStarterTemplates.findById('brainstorming_project')!;
      final (cards, arrows) = t.builder('board_bs');

      expect(cards.length, equals(6));
      expect(arrows.length, equals(4));

      final centerId = 'board_bs_bs_center';
      for (final arrow in arrows) {
        expect(arrow.startCardId, equals(centerId));
      }
    });
  });
}
