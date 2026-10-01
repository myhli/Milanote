import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:localboard/features/export_import/board_bundle/board_bundle_service.dart';
import 'package:localboard/features/storage/data/asset_manager.dart';
import 'package:localboard/features/storage/data/hive_board_repository.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';

void main() {
  group('BoardBundleService Tests (PKG-02 & US-011)', () {
    late Directory tempDir;
    late AssetManager assetManager;
    late HiveBoardRepository repository;
    late BoardBundleService bundleService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('localboard_bundle_test_');
      Hive.init(tempDir.path);

      assetManager = AssetManager(
        baseDirProvider: () async => tempDir,
      );

      repository = HiveBoardRepository(
        assetManager: assetManager,
      );
      await repository.init();

      bundleService = BoardBundleService(
        repository: repository,
        assetManager: assetManager,
      );
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('createBundleBytes packs manifest, canvas data, and assets into standalone ZIP', () async {
      // 1. Prepare sample board with asset
      const boardId = 'source_board_123';
      final assetPath = await assetManager.saveAsset(
        boardId: boardId,
        bytes: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        fileExtension: 'png',
      );

      final now = DateTime.now();
      final meta = BoardMetadata(
        id: boardId,
        title: 'Papan Seni Konseptual',
        createdAt: now,
        updatedAt: now,
        cardCount: 2,
      );

      final canvas = CanvasData(
        boardId: boardId,
        cards: [
          {
            'id': 'note-1',
            'type': 'note',
            'title': 'Catatan Konsep',
            'content': 'Deskripsi ide karakter.',
          },
          {
            'id': 'img-1',
            'type': 'image',
            'assetUuid': assetPath,
            'caption': 'Tekstur armor',
          },
        ],
        arrows: [],
        updatedAt: now,
      );

      // 2. Create bundle
      final bundleBytes = await bundleService.createBundleBytes(
        metadata: meta,
        canvasData: canvas,
      );

      expect(bundleBytes, isNotEmpty);

      // 3. Inspect zip container directly with ZipDecoder
      final archive = ZipDecoder().decodeBytes(bundleBytes);
      final fileNames = archive.map((f) => f.name).toList();

      expect(fileNames, contains('manifest.json'));
      expect(fileNames, contains('canvas_data.json'));
      expect(fileNames.any((n) => n.startsWith('assets/')), isTrue);
    });

    test('importBundleBytes unpacks zip, creates new board ID, extracts assets, and stores to DB', () async {
      // 1. Create a bundle first
      const sourceId = 'original_board_999';
      final dummyAssetBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      final origAssetPath = await assetManager.saveAsset(
        boardId: sourceId,
        bytes: dummyAssetBytes,
        fileExtension: 'jpg',
      );

      final now = DateTime.now();
      final meta = BoardMetadata(
        id: sourceId,
        title: 'Master Moodboard',
        createdAt: now,
        updatedAt: now,
        cardCount: 1,
      );

      final canvas = CanvasData(
        boardId: sourceId,
        cards: [
          {
            'id': 'card-img-1',
            'type': 'image',
            'assetUuid': origAssetPath,
            'caption': 'Lukisan pemandangan',
          },
        ],
        arrows: [],
        updatedAt: now,
      );

      final bundleBytes = await bundleService.createBundleBytes(
        metadata: meta,
        canvasData: canvas,
      );

      // 2. Import into a fresh board instance
      final importedMeta = await bundleService.importBundleBytes(
        bundleBytes: bundleBytes,
        customTitle: 'Master Moodboard Impor',
      );

      // 3. Verify independent ID created
      expect(importedMeta.id, isNot(equals(sourceId)));
      expect(importedMeta.title, 'Master Moodboard Impor');

      // 4. Verify board exists in repository
      final fetchedMeta = await repository.getBoardMetadata(importedMeta.id);
      expect(fetchedMeta, isNotNull);
      expect(fetchedMeta?.title, 'Master Moodboard Impor');

      final fetchedCanvas = await repository.getCanvasData(importedMeta.id);
      expect(fetchedCanvas, isNotNull);
      expect(fetchedCanvas?.cards, hasLength(1));

      // 5. Verify asset was extracted and remapped
      final remappedAsset = fetchedCanvas?.cards.first['assetUuid'] as String?;
      expect(remappedAsset, isNotNull);
      expect(remappedAsset, isNotEmpty);

      final extractedFile = await assetManager.getAssetFile(
        boardId: importedMeta.id,
        relativePath: remappedAsset!,
      );
      expect(extractedFile, isNotNull);
      expect(await extractedFile.exists(), isTrue);
      expect(await extractedFile.readAsBytes(), dummyAssetBytes);
    });

    test('importBundleBytes throws FormatException when zip is corrupt or missing files', () async {
      final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4]);

      expect(
        () => bundleService.importBundleBytes(bundleBytes: invalidBytes),
        throwsA(isA<Exception>()),
      );
    });
  });
}
