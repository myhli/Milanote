import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:localboard/features/storage/data/asset_manager.dart';
import 'package:localboard/features/storage/data/hive_board_repository.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';

void main() {
  group('HiveBoardRepository', () {
    late Directory tempDir;
    late AssetManager assetManager;
    late HiveBoardRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('localboard_hive_test_');
      Hive.init(tempDir.path);

      assetManager = AssetManager(
        baseDirProvider: () async => tempDir,
      );

      repository = HiveBoardRepository(
        assetManager: assetManager,
      );
      await repository.init();
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveBoard and getBoards persists and sorts by updatedAt descending', () async {
      final now = DateTime.now();
      final board1 = BoardMetadata(
        id: 'b1',
        title: 'Board 1',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        cardCount: 2,
      );
      final canvas1 = CanvasData(
        boardId: 'b1',
        cards: [
          {'id': 'c1', 'type': 'note'},
          {'id': 'c2', 'type': 'image'},
        ],
        updatedAt: board1.updatedAt,
      );

      final board2 = BoardMetadata(
        id: 'b2',
        title: 'Board 2 (Latest)',
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now,
        cardCount: 1,
      );
      final canvas2 = CanvasData(
        boardId: 'b2',
        cards: [
          {'id': 'c3', 'type': 'color'},
        ],
        updatedAt: board2.updatedAt,
      );

      await repository.saveBoard(metadata: board1, canvasData: canvas1);
      await repository.saveBoard(metadata: board2, canvasData: canvas2);

      final boards = await repository.getBoards();
      expect(boards.length, equals(2));
      // board2 was updated more recently than board1, so it must be first
      expect(boards.first.id, equals('b2'));
      expect(boards.last.id, equals('b1'));

      final retrievedCanvas = await repository.getCanvasData('b1');
      expect(retrievedCanvas, isNotNull);
      expect(retrievedCanvas!.cards.length, equals(2));
    });

    test('updateMetadata updates title without altering canvas data', () async {
      final now = DateTime.now();
      final metadata = BoardMetadata(
        id: 'b-rename',
        title: 'Original Title',
        createdAt: now,
        updatedAt: now,
      );
      final canvas = CanvasData(
        boardId: 'b-rename',
        cards: [
          {'id': 'c1', 'text': 'Important concept'},
        ],
        updatedAt: now,
      );

      await repository.saveBoard(metadata: metadata, canvasData: canvas);

      final updatedMetadata = metadata.copyWith(title: 'Renamed Art Project');
      await repository.updateMetadata(updatedMetadata);

      final fetched = await repository.getBoardMetadata('b-rename');
      expect(fetched?.title, equals('Renamed Art Project'));

      final fetchedCanvas = await repository.getCanvasData('b-rename');
      expect(fetchedCanvas?.cards.length, equals(1));
    });

    test('updateCanvasData updates cards and auto-syncs metadata cardCount', () async {
      final now = DateTime.now();
      final metadata = BoardMetadata(
        id: 'b-cards',
        title: 'Dynamic Cards Board',
        createdAt: now,
        updatedAt: now,
        cardCount: 0,
      );
      final canvas = CanvasData(
        boardId: 'b-cards',
        cards: const [],
        updatedAt: now,
      );

      await repository.saveBoard(metadata: metadata, canvasData: canvas);

      final newCanvas = canvas.copyWith(
        cards: [
          {'id': '1', 'type': 'note'},
          {'id': '2', 'type': 'image'},
          {'id': '3', 'type': 'color'},
        ],
        updatedAt: DateTime.now(),
      );
      await repository.updateCanvasData(newCanvas);

      final fetchedCanvas = await repository.getCanvasData('b-cards');
      expect(fetchedCanvas?.cards.length, equals(3));

      final fetchedMetadata = await repository.getBoardMetadata('b-cards');
      expect(fetchedMetadata?.cardCount, equals(3));
    });

    test('duplicateBoard creates fresh board with independent ID', () async {
      final now = DateTime.now();
      final metadata = BoardMetadata(
        id: 'b-source',
        title: 'Original Project',
        createdAt: now,
        updatedAt: now,
        cardCount: 1,
      );
      final canvas = CanvasData(
        boardId: 'b-source',
        cards: [
          {'id': 'card-1', 'title': 'Character concept'},
        ],
        updatedAt: now,
      );

      await repository.saveBoard(metadata: metadata, canvasData: canvas);

      final duplicated = await repository.duplicateBoard(
        sourceBoardId: 'b-source',
        newTitle: 'Copy of Original Project',
      );

      expect(duplicated.id, isNot(equals('b-source')));
      expect(duplicated.title, equals('Copy of Original Project'));

      final duplicatedCanvas = await repository.getCanvasData(duplicated.id);
      expect(duplicatedCanvas, isNotNull);
      expect(duplicatedCanvas!.boardId, equals(duplicated.id));
      expect(duplicatedCanvas.cards.length, equals(1));
    });

    test('deleteBoard removes metadata, canvas data and triggers asset cleanup', () async {
      final now = DateTime.now();
      final metadata = BoardMetadata(
        id: 'b-delete',
        title: 'To Be Deleted',
        createdAt: now,
        updatedAt: now,
      );
      final canvas = CanvasData(
        boardId: 'b-delete',
        cards: const [],
        updatedAt: now,
      );

      await repository.saveBoard(metadata: metadata, canvasData: canvas);

      // Save an asset for this board
      await assetManager.saveAsset(
        boardId: 'b-delete',
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'png',
      );
      final assetsBefore = await assetManager.listBoardAssets('b-delete');
      expect(assetsBefore.length, equals(1));

      await repository.deleteBoard('b-delete');

      expect(await repository.getBoardMetadata('b-delete'), isNull);
      expect(await repository.getCanvasData('b-delete'), isNull);

      final assetsAfter = await assetManager.listBoardAssets('b-delete');
      expect(assetsAfter.isEmpty, isTrue);
    });
  });
}
