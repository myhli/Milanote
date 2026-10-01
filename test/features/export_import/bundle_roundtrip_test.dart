import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:localboard/features/cards/models/color_card.dart';
import 'package:localboard/features/cards/models/connector_arrow.dart';
import 'package:localboard/features/cards/models/image_card.dart';
import 'package:localboard/features/cards/models/link_card.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/models/subboard_card.dart';
import 'package:localboard/features/export_import/board_bundle/board_bundle_service.dart';
import 'package:localboard/features/export_import/board_bundle/manifest_schema.dart';
import 'package:localboard/features/storage/data/asset_manager.dart';
import 'package:localboard/features/storage/data/hive_board_repository.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';

void main() {
  group('Comprehensive .board Bundle Roundtrip & Portability Tests (US-011, PKG-01, PKG-02)', () {
    late Directory machineADir;
    late Directory machineBDir;

    setUp(() async {
      machineADir = await Directory.systemTemp.createTemp('machine_a_');
      machineBDir = await Directory.systemTemp.createTemp('machine_b_');
    });

    tearDown(() async {
      await Hive.close();
      if (await machineADir.exists()) {
        await machineADir.delete(recursive: true);
      }
      if (await machineBDir.exists()) {
        await machineBDir.delete(recursive: true);
      }
    });

    test('Full End-to-End Roundtrip: Export on Machine A, Validate ZIP, and Import into Machine B', () async {
      // ==========================================
      // STAGE 1: Setup Machine A (Origin Studio)
      // ==========================================
      Hive.init(machineADir.path);
      final assetManagerA = AssetManager(baseDirProvider: () async => machineADir);
      final repoA = HiveBoardRepository(assetManager: assetManagerA);
      await repoA.init();
      final bundleServiceA = BoardBundleService(repository: repoA, assetManager: assetManagerA);

      const originalBoardId = 'art_studio_project_001';
      final now = DateTime.now();

      // Create raw sample image binary (mock 512-byte PNG header & data)
      final sampleImageBytes = Uint8List.fromList(
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, ...List.generate(500, (i) => (i * 7) % 256)],
      );
      final sampleCoverBytes = Uint8List.fromList(
        [0xFF, 0xD8, 0xFF, 0xE0, ...List.generate(200, (i) => (i * 13) % 256)],
      );

      final imageAssetUuid = await assetManagerA.saveAsset(
        boardId: originalBoardId,
        bytes: sampleImageBytes,
        fileExtension: 'png',
      );
      final coverAssetUuid = await assetManagerA.saveAsset(
        boardId: originalBoardId,
        bytes: sampleCoverBytes,
        fileExtension: 'jpg',
      );

      // Create rich diverse board content
      final noteCard = NoteCard(
        id: 'note_1',
        x: 100,
        y: 120,
        width: 300,
        height: 220,
        title: '🎨 Karakter Utama: Aerith',
        content: 'Konsep siluet, kostum pastel, dan proporsi anatomis dinamis.',
        colorHex: '#FEF9C3',
        checklists: const [
          ChecklistItem(id: 'c1', text: 'Sketsa awal pose 3/4', isDone: true),
          ChecklistItem(id: 'c2', text: 'Studi pencahayaan rim light', isDone: false),
          ChecklistItem(id: 'c3', text: 'Riset pola tekstur gaun', isDone: true),
        ],
        isChecklistMode: true,
        createdAt: now,
        updatedAt: now,
      );

      final imageCard = ImageCard(
        id: 'image_1',
        x: 450,
        y: 120,
        width: 320,
        height: 240,
        assetUuid: imageAssetUuid,
        caption: 'Referensi Tekstur Sutra & Sutra Emas',
        createdAt: now,
        updatedAt: now,
      );

      final colorCard = ColorCard(
        id: 'color_1',
        x: 100,
        y: 400,
        width: 300,
        height: 180,
        title: 'Palet Suasana Sore (Sunset Horizon)',
        colorsHex: const ['#2C3E50', '#E74C3C', '#E67E22', '#F1C40F', '#ECF0F1'],
        createdAt: now,
        updatedAt: now,
      );

      final linkCard = LinkCard(
        id: 'link_1',
        x: 450,
        y: 400,
        width: 320,
        height: 200,
        url: 'https://artstation.com/artwork/sample-concept',
        title: 'Inspirasi Gaun Dinamis - ArtStation',
        description: 'Studi lipatan kain dan aliran bayangan artistik.',
        coverAssetUuid: coverAssetUuid,
        createdAt: now,
        updatedAt: now,
      );

      final subBoardCard = SubBoardCard(
        id: 'subboard_1',
        x: 820,
        y: 200,
        width: 280,
        height: 180,
        targetBoardId: 'child_storyboard_board',
        title: 'Storyboard Bab 1',
        cardCount: 12,
        createdAt: now,
        updatedAt: now,
      );

      final arrow1 = const ConnectorArrow(
        id: 'arrow_note_to_image',
        startCardId: 'note_1',
        endCardId: 'image_1',
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.curved,
        head: ArrowHead.end,
        strokeWidth: 2.5,
      );

      final arrow2 = const ConnectorArrow(
        id: 'arrow_image_to_subboard',
        startCardId: 'image_1',
        endCardId: 'subboard_1',
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.orthogonal,
        head: ArrowHead.both,
        strokeWidth: 2.0,
      );

      final originMeta = BoardMetadata(
        id: originalBoardId,
        title: 'Proyek Konsep Desain Karakter',
        createdAt: now,
        updatedAt: now,
        cardCount: 5,
      );

      final originCanvas = CanvasData(
        boardId: originalBoardId,
        cards: [
          noteCard.toJson(),
          imageCard.toJson(),
          colorCard.toJson(),
          linkCard.toJson(),
          subBoardCard.toJson(),
        ],
        arrows: [
          arrow1.toJson(),
          arrow2.toJson(),
        ],
        updatedAt: now,
      );

      await repoA.saveBoard(metadata: originMeta, canvasData: originCanvas);

      // ==========================================
      // STAGE 2: Export Board to .board ZIP Bytes
      // ==========================================
      final bundleBytes = await bundleServiceA.createBundleBytes(
        metadata: originMeta,
        canvasData: originCanvas,
      );

      expect(bundleBytes, isNotEmpty);

      // ==========================================
      // STAGE 3: Strict ZIP Container Inspection
      // ==========================================
      final archive = ZipDecoder().decodeBytes(bundleBytes);

      // Must contain manifest.json, canvas_data.json, and assets/
      final entries = {for (final f in archive) f.name: f};
      expect(entries.containsKey('manifest.json'), isTrue);
      expect(entries.containsKey('canvas_data.json'), isTrue);

      // Validate manifest.json schema
      final manifestJsonStr = utf8.decode(entries['manifest.json']!.content as List<int>);
      final manifestMap = jsonDecode(manifestJsonStr) as Map<String, dynamic>;

      expect(manifestMap['schemaVersion'], equals(BoardBundleManifest.currentSchemaVersion));
      expect(manifestMap['title'], equals('Proyek Konsep Desain Karakter'));
      expect(manifestMap['cardCount'], equals(5));
      expect(manifestMap['arrowCount'], equals(2));
      expect(manifestMap['assetCount'], equals(2));

      final assetList = List<String>.from(manifestMap['assetList'] as List);
      expect(assetList.length, equals(2));

      for (final assetEntryName in assetList) {
        expect(entries.containsKey(assetEntryName), isTrue, reason: 'ZIP must contain all assets declared in manifest');
      }

      // Check binary equality of packaged image asset in ZIP
      final packagedImageName = assetList.firstWhere((n) => n.endsWith('.png'));
      final packagedImageFile = entries[packagedImageName]!;
      expect(packagedImageFile.content as List<int>, equals(sampleImageBytes));

      // Close Machine A to simulate total separation
      await Hive.close();

      // ==========================================
      // STAGE 4: Import into Clean Machine B
      // ==========================================
      Hive.init(machineBDir.path);
      final assetManagerB = AssetManager(baseDirProvider: () async => machineBDir);
      final repoB = HiveBoardRepository(assetManager: assetManagerB);
      await repoB.init();
      final bundleServiceB = BoardBundleService(repository: repoB, assetManager: assetManagerB);

      final importedMetadata = await bundleServiceB.importBundleBytes(
        bundleBytes: bundleBytes,
        customTitle: 'Proyek Karakter (Imported)',
      );

      // Assert new unique board ID allocated
      expect(importedMetadata.id, isNot(equals(originalBoardId)));
      expect(importedMetadata.title, equals('Proyek Karakter (Imported)'));
      expect(importedMetadata.cardCount, equals(5));

      // Assert Canvas Data recovered 100%
      final importedCanvas = await repoB.getCanvasData(importedMetadata.id);
      expect(importedCanvas, isNotNull);
      expect(importedCanvas!.cards.length, equals(5));
      expect(importedCanvas.arrows.length, equals(2));

      // 1. Verify NoteCard
      final noteMap = importedCanvas.cards.firstWhere((c) => c['id'] == 'note_1');
      expect(noteMap['title'], equals('🎨 Karakter Utama: Aerith'));
      expect(noteMap['colorHex'], equals('#FEF9C3'));
      expect((noteMap['checklists'] as List).length, equals(3));
      expect((noteMap['checklists'] as List)[0]['text'], equals('Sketsa awal pose 3/4'));
      expect((noteMap['checklists'] as List)[0]['isDone'], isTrue);
      expect((noteMap['checklists'] as List)[1]['isDone'], isFalse);

      // 2. Verify ColorCard
      final colorMap = importedCanvas.cards.firstWhere((c) => c['id'] == 'color_1');
      expect(colorMap['title'], equals('Palet Suasana Sore (Sunset Horizon)'));
      expect(colorMap['colorsHex'], equals(['#2C3E50', '#E74C3C', '#E67E22', '#F1C40F', '#ECF0F1']));

      // 3. Verify SubBoardCard
      final subboardMap = importedCanvas.cards.firstWhere((c) => c['id'] == 'subboard_1');
      expect(subboardMap['targetBoardId'], equals('child_storyboard_board'));
      expect(subboardMap['cardCount'], equals(12));

      // 4. Verify ConnectorArrows
      final arrowMap1 = importedCanvas.arrows.firstWhere((a) => a['id'] == 'arrow_note_to_image');
      expect(arrowMap1['startCardId'], equals('note_1'));
      expect(arrowMap1['endCardId'], equals('image_1'));
      expect(arrowMap1['style'], equals('curved'));
      expect(arrowMap1['strokeWidth'], equals(2.5));

      // 5. Verify ImageCard asset extraction and sandboxing
      final imgMap = importedCanvas.cards.firstWhere((c) => c['id'] == 'image_1');
      final newAssetUuid = imgMap['assetUuid'] as String;
      expect(newAssetUuid, isNotEmpty);
      expect(newAssetUuid.startsWith('assets/'), isTrue);

      // Read extracted file from Machine B's sandbox
      final extractedBytes = await assetManagerB.getAssetBytes(
        boardId: importedMetadata.id,
        relativePath: newAssetUuid,
      );
      expect(extractedBytes, isNotNull);
      expect(extractedBytes, equals(sampleImageBytes), reason: 'Binary image must match original byte-for-byte');

      // 6. Verify LinkCard cover asset extraction
      final linkMap = importedCanvas.cards.firstWhere((c) => c['id'] == 'link_1');
      final newCoverUuid = linkMap['coverAssetUuid'] as String;
      expect(newCoverUuid, isNotEmpty);
      final extractedCoverBytes = await assetManagerB.getAssetBytes(
        boardId: importedMetadata.id,
        relativePath: newCoverUuid,
      );
      expect(extractedCoverBytes, isNotNull);
      expect(extractedCoverBytes, equals(sampleCoverBytes));
    });

    test('Corrupted bundle or missing manifest throws clear friendly FormatException', () async {
      Hive.init(machineBDir.path);
      final assetManagerB = AssetManager(baseDirProvider: () async => machineBDir);
      final repoB = HiveBoardRepository(assetManager: assetManagerB);
      await repoB.init();
      final bundleService = BoardBundleService(repository: repoB, assetManager: assetManagerB);

      // Case 1: Corrupted non-zip random bytes
      final garbageBytes = Uint8List.fromList([0x00, 0xFF, 0x12, 0x34, 0x56]);
      expect(
        () => bundleService.importBundleBytes(bundleBytes: garbageBytes),
        throwsA(isA<Exception>()),
      );

      // Case 2: Valid ZIP but missing manifest.json
      final zipWithoutManifest = Archive();
      zipWithoutManifest.addFile(
        ArchiveFile('canvas_data.json', 2, utf8.encode('{}')),
      );
      final zipBytesNoManifest = Uint8List.fromList(ZipEncoder().encode(zipWithoutManifest));

      expect(
        () => bundleService.importBundleBytes(bundleBytes: zipBytesNoManifest),
        throwsA(
          predicate((e) =>
              e is FormatException &&
              e.message.contains('manifest.json atau canvas_data.json tidak ditemukan')),
        ),
      );

      // Case 3: Valid ZIP and manifest but missing canvas_data.json
      final zipWithoutCanvas = Archive();
      final validManifest = BoardBundleManifest(
        exportDate: DateTime.now(),
        boardId: 'test_id',
        title: 'Missing Canvas Board',
        cardCount: 0,
        arrowCount: 0,
        assetCount: 0,
      );
      final manifestBytes = utf8.encode(jsonEncode(validManifest.toJson()));
      zipWithoutCanvas.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
      final zipBytesNoCanvas = Uint8List.fromList(ZipEncoder().encode(zipWithoutCanvas));

      expect(
        () => bundleService.importBundleBytes(bundleBytes: zipBytesNoCanvas),
        throwsA(
          predicate((e) =>
              e is FormatException &&
              e.message.contains('manifest.json atau canvas_data.json tidak ditemukan')),
        ),
      );
    });
  });
}
