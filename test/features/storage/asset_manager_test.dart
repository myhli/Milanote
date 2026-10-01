import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/storage/data/asset_manager.dart';

void main() {
  group('AssetManager', () {
    late Directory tempDir;
    late AssetManager assetManager;
    const testBoardId = 'test-board-123';

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('localboard_asset_test_');
      assetManager = AssetManager(
        baseDirProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveAsset writes bytes and returns relative path format', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final relativePath = await assetManager.saveAsset(
        boardId: testBoardId,
        bytes: sampleBytes,
        fileExtension: '.png',
      );

      expect(relativePath.startsWith('assets/'), isTrue);
      expect(relativePath.endsWith('.png'), isTrue);

      final readBytes = await assetManager.getAssetBytes(
        boardId: testBoardId,
        relativePath: relativePath,
      );
      expect(readBytes, isNotNull);
      expect(listEquals(readBytes, sampleBytes), isTrue);
    });

    test('resolveAssetPath returns absolute path pointing to sandbox', () async {
      final sampleBytes = Uint8List.fromList([10, 20, 30]);
      final relativePath = await assetManager.saveAsset(
        boardId: testBoardId,
        bytes: sampleBytes,
        fileExtension: 'jpg',
      );

      final absolutePath = await assetManager.resolveAssetPath(
        boardId: testBoardId,
        relativePath: relativePath,
      );

      expect(absolutePath.contains(tempDir.path), isTrue);
      expect(File(absolutePath).existsSync(), isTrue);
    });

    test('listBoardAssets lists all saved assets for board', () async {
      await assetManager.saveAsset(
        boardId: testBoardId,
        bytes: Uint8List.fromList([1]),
        fileExtension: 'png',
      );
      await assetManager.saveAsset(
        boardId: testBoardId,
        bytes: Uint8List.fromList([2]),
        fileExtension: 'webp',
      );

      final assets = await assetManager.listBoardAssets(testBoardId);
      expect(assets.length, equals(2));
      expect(assets.every((a) => a.startsWith('assets/')), isTrue);
    });

    test('deleteAsset deletes target file and returns true', () async {
      final relativePath = await assetManager.saveAsset(
        boardId: testBoardId,
        bytes: Uint8List.fromList([1, 2]),
        fileExtension: 'png',
      );

      final deleted = await assetManager.deleteAsset(
        boardId: testBoardId,
        relativePath: relativePath,
      );
      expect(deleted, isTrue);

      final readAgain = await assetManager.getAssetBytes(
        boardId: testBoardId,
        relativePath: relativePath,
      );
      expect(readAgain, isNull);
    });

    test('deleteBoardAssets removes entire board assets directory', () async {
      await assetManager.saveAsset(
        boardId: testBoardId,
        bytes: Uint8List.fromList([1]),
        fileExtension: 'png',
      );

      await assetManager.deleteBoardAssets(testBoardId);

      final assets = await assetManager.listBoardAssets(testBoardId);
      expect(assets.isEmpty, isTrue);
    });
  });
}
