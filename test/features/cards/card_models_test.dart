import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/base_card.dart';
import 'package:localboard/features/cards/models/color_card.dart';
import 'package:localboard/features/cards/models/image_card.dart';
import 'package:localboard/features/cards/models/note_card.dart';

void main() {
  group('Card Models Tests (CRD-01)', () {
    final now = DateTime.now();

    test('NoteCard serialization and mutation', () {
      final note = NoteCard(
        id: 'note-1',
        x: 100,
        y: 200,
        width: 300,
        height: 250,
        title: 'Konsep Desain',
        content: 'Catatan penting untuk pameran.',
        colorHex: '#FEF9C3',
        checklists: const [
          ChecklistItem(id: 'c1', text: 'Sketsa anatomi', isDone: true),
          ChecklistItem(id: 'c2', text: 'Tinta garis', isDone: false),
        ],
        isChecklistMode: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = note.toJson();
      final fromJson = BaseCard.fromJson(json) as NoteCard;

      expect(fromJson.id, equals('note-1'));
      expect(fromJson.title, equals('Konsep Desain'));
      expect(fromJson.checklists.length, equals(2));
      expect(fromJson.checklists.first.isDone, isTrue);
      expect(fromJson.colorHex, equals('#FEF9C3'));

      final moved = note.moveTo(150, 250);
      expect(moved.x, equals(150));
      expect(moved.y, equals(250));

      final resized = note.resizeTo(400, 350);
      expect(resized.width, equals(400));
      expect(resized.height, equals(350));
    });

    test('ImageCard proportional resize and serialization', () {
      final img = ImageCard(
        id: 'img-1',
        x: 50,
        y: 60,
        width: 400,
        height: 300,
        aspectRatio: 4 / 3,
        assetUuid: 'assets/image_uuid_123.png',
        caption: 'Pemandangan Studio',
        createdAt: now,
        updatedAt: now,
      );

      final json = img.toJson();
      final fromJson = BaseCard.fromJson(json) as ImageCard;

      expect(fromJson.id, equals('img-1'));
      expect(fromJson.assetUuid, equals('assets/image_uuid_123.png'));
      expect(fromJson.caption, equals('Pemandangan Studio'));

      // Resizing with width 600 maintains aspect ratio 4/3 -> height = 450
      final resized = img.resizeTo(600, 500);
      expect(resized.width, equals(600));
      expect(resized.height, closeTo(450.0, 0.01));
    });

    test('ColorCard palette swatches and serialization', () {
      final colorCard = ColorCard(
        id: 'col-1',
        x: 0,
        y: 0,
        title: 'Skema Warna Karakter',
        colorsHex: const ['#112233', '#445566', '#778899'],
        createdAt: now,
        updatedAt: now,
      );

      final json = colorCard.toJson();
      final fromJson = BaseCard.fromJson(json) as ColorCard;

      expect(fromJson.id, equals('col-1'));
      expect(fromJson.title, equals('Skema Warna Karakter'));
      expect(fromJson.colorsHex, equals(['#112233', '#445566', '#778899']));
    });
  });
}
