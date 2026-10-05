import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/board_metadata.dart';
import '../domain/board_repository.dart';
import '../domain/canvas_data.dart';
import 'asset_manager.dart';

/// Concrete implementation of [BoardRepository] utilizing [Hive] key-value document storage.
/// Fast, zero-C-dependency, and fully offline-first.
class HiveBoardRepository implements BoardRepository {
  static const String metadataBoxName = 'localboard_metadata_box';
  static const String canvasBoxName = 'localboard_canvas_box';

  final AssetManager? _assetManager;
  final Uuid _uuid;

  Box<Map>? _metadataBox;
  Box<Map>? _canvasBox;

  HiveBoardRepository({
    this._assetManager,
    Uuid? uuid,
    this._metadataBox,
    this._canvasBox,
  })  : _uuid = uuid ?? const Uuid();

  @override
  Future<void> init() async {
    try {
      if (_metadataBox == null || !_metadataBox!.isOpen) {
        if (Hive.isBoxOpen(metadataBoxName)) {
          _metadataBox = Hive.box<Map>(metadataBoxName);
        } else {
          _metadataBox = await Hive.openBox<Map>(metadataBoxName);
        }
      }
      if (_canvasBox == null || !_canvasBox!.isOpen) {
        if (Hive.isBoxOpen(canvasBoxName)) {
          _canvasBox = Hive.box<Map>(canvasBoxName);
        } else {
          _canvasBox = await Hive.openBox<Map>(canvasBoxName);
        }
      }
    } catch (e) {
      debugPrint('Warning: HiveBoardRepository.init() could not open boxes: $e');
    }
  }

  Box<Map> get metadataBox {
    if (_metadataBox != null && _metadataBox!.isOpen) {
      return _metadataBox!;
    }
    if (Hive.isBoxOpen(metadataBoxName)) {
      _metadataBox = Hive.box<Map>(metadataBoxName);
      return _metadataBox!;
    }
    throw StateError('HiveBoardRepository has not been initialized. Call init() first.');
  }

  Box<Map> get canvasBox {
    if (_canvasBox != null && _canvasBox!.isOpen) {
      return _canvasBox!;
    }
    if (Hive.isBoxOpen(canvasBoxName)) {
      _canvasBox = Hive.box<Map>(canvasBoxName);
      return _canvasBox!;
    }
    throw StateError('HiveBoardRepository has not been initialized. Call init() first.');
  }

  @override
  Future<List<BoardMetadata>> getBoards() async {
    await init();
    if (_metadataBox == null || !_metadataBox!.isOpen) {
      return [];
    }
    final box = metadataBox;
    final List<BoardMetadata> boards = [];

    for (final key in box.keys) {
      final rawData = box.get(key);
      if (rawData != null) {
        try {
          boards.add(BoardMetadata.fromJson(rawData));
        } catch (e) {
          debugPrint('Error deserializing board metadata for key $key: $e');
        }
      }
    }

    // Sort boards by last updated date descending
    boards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return boards;
  }

  @override
  Future<BoardMetadata?> getBoardMetadata(String boardId) async {
    await init();
    if (_metadataBox == null || !_metadataBox!.isOpen) {
      return null;
    }
    final rawData = metadataBox.get(boardId);
    if (rawData == null) return null;
    return BoardMetadata.fromJson(rawData);
  }

  @override
  Future<CanvasData?> getCanvasData(String boardId) async {
    await init();
    if (_canvasBox == null || !_canvasBox!.isOpen) {
      return null;
    }
    final rawData = canvasBox.get(boardId);
    if (rawData == null) return null;
    return CanvasData.fromJson(rawData);
  }

  @override
  Future<void> saveBoard({
    required BoardMetadata metadata,
    required CanvasData canvasData,
  }) async {
    await init();
    if (_metadataBox != null && _metadataBox!.isOpen) {
      await metadataBox.put(metadata.id, metadata.toJson());
    }
    if (_canvasBox != null && _canvasBox!.isOpen) {
      await canvasBox.put(canvasData.boardId, canvasData.toJson());
    }
  }

  @override
  Future<void> updateMetadata(BoardMetadata metadata) async {
    await init();
    if (_metadataBox != null && _metadataBox!.isOpen) {
      await metadataBox.put(metadata.id, metadata.toJson());
    }
  }

  @override
  Future<void> updateCanvasData(CanvasData canvasData) async {
    await init();
    if (_canvasBox != null && _canvasBox!.isOpen) {
      await canvasBox.put(canvasData.boardId, canvasData.toJson());
    }

    // Also update cardCount and updatedAt in metadata if available
    final existingMetadata = await getBoardMetadata(canvasData.boardId);
    if (existingMetadata != null && _metadataBox != null && _metadataBox!.isOpen) {
      final updated = existingMetadata.copyWith(
        cardCount: canvasData.cards.length,
        updatedAt: canvasData.updatedAt,
      );
      await metadataBox.put(updated.id, updated.toJson());
    }
  }

  @override
  Future<void> deleteBoard(String boardId) async {
    await init();
    if (_metadataBox != null && _metadataBox!.isOpen) {
      await metadataBox.delete(boardId);
    }
    if (_canvasBox != null && _canvasBox!.isOpen) {
      await canvasBox.delete(boardId);
    }

    // Clean up associated local sandboxed assets
    if (_assetManager != null) {
      await _assetManager.deleteBoardAssets(boardId);
    }
  }

  @override
  Future<BoardMetadata> duplicateBoard({
    required String sourceBoardId,
    required String newTitle,
  }) async {
    await init();
    final sourceMetadata = await getBoardMetadata(sourceBoardId);
    final sourceCanvas = await getCanvasData(sourceBoardId);

    final newBoardId = _uuid.v4();
    final now = DateTime.now();

    final newMetadata = BoardMetadata(
      id: newBoardId,
      title: newTitle,
      thumbnailPath: sourceMetadata?.thumbnailPath,
      createdAt: now,
      updatedAt: now,
      cardCount: sourceMetadata?.cardCount ?? 0,
    );

    final newCanvas = (sourceCanvas != null)
        ? sourceCanvas.copyWith(
            boardId: newBoardId,
            updatedAt: now,
          )
        : CanvasData(
            boardId: newBoardId,
            updatedAt: now,
          );

    await saveBoard(metadata: newMetadata, canvasData: newCanvas);
    return newMetadata;
  }
}
