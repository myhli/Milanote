import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/color_card.dart';
import 'package:localboard/features/cards/models/connector_arrow.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/export_import/image_export/canvas_rasterizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CanvasRasterizer Tests (EXP-02)', () {
    test('rasterizeToPng generates valid PNG byte array with PNG magic header', () async {
      final now = DateTime.now();
      final cards = [
        NoteCard(
          id: 'note-1',
          x: 50,
          y: 50,
          width: 250,
          height: 180,
          zIndex: 1,
          title: 'Konsep Desain',
          content: 'Eksperimen warna dan tipografi.',
          checklists: const [
            ChecklistItem(id: 'c1', text: 'Task 1', isDone: true),
            ChecklistItem(id: 'c2', text: 'Task 2', isDone: false),
          ],
          isChecklistMode: true,
          colorHex: '#FEF9C3',
          createdAt: now,
          updatedAt: now,
        ),
        ColorCard(
          id: 'color-1',
          x: 350,
          y: 50,
          width: 300,
          height: 130,
          zIndex: 2,
          title: 'Palet Warna',
          colorsHex: const ['#2C3E50', '#E74C3C', '#3498DB', '#F1C40F'],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      const arrows = [
        ConnectorArrow(
          id: 'arr-1',
          startCardId: 'note-1',
          endCardId: 'color-1',
          style: ArrowStyle.curved,
        ),
      ];

      final bounds = const Rect.fromLTWH(0, 0, 700, 300);

      final pngBytes = await CanvasRasterizer.rasterizeToPng(
        cards: cards,
        arrows: arrows,
        bounds: bounds,
        scale: 1.0,
        isDark: true,
      );

      expect(pngBytes, isNotEmpty);
      // Verify PNG magic number: 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
      expect(pngBytes.length, greaterThan(8));
      expect(pngBytes[0], equals(0x89));
      expect(pngBytes[1], equals(0x50)); // 'P'
      expect(pngBytes[2], equals(0x4E)); // 'N'
      expect(pngBytes[3], equals(0x47)); // 'G'
      expect(pngBytes[4], equals(0x0D));
      expect(pngBytes[5], equals(0x0A));
      expect(pngBytes[6], equals(0x1A));
      expect(pngBytes[7], equals(0x0A));
    });

    test('rasterizeToPng handles 2x scale properly', () async {
      final now = DateTime.now();
      final cards = [
        NoteCard(
          id: 'n1',
          x: 0,
          y: 0,
          width: 200,
          height: 200,
          zIndex: 1,
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final bytes1x = await CanvasRasterizer.rasterizeToPng(
        cards: cards,
        arrows: const [],
        bounds: const Rect.fromLTWH(0, 0, 200, 200),
        scale: 1.0,
      );

      final bytes2x = await CanvasRasterizer.rasterizeToPng(
        cards: cards,
        arrows: const [],
        bounds: const Rect.fromLTWH(0, 0, 200, 200),
        scale: 2.0,
      );

      expect(bytes1x, isNotEmpty);
      expect(bytes2x, isNotEmpty);
      // Higher resolution raster typically produces larger byte arrays
      expect(bytes2x.length, greaterThan(bytes1x.length));
    });
  });
}
