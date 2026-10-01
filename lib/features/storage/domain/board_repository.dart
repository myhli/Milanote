import 'board_metadata.dart';
import 'canvas_data.dart';

/// Abstract repository defining contracts for local board and canvas persistence.
abstract class BoardRepository {
  /// Initializes the local database storage engine (e.g. Hive boxes).
  Future<void> init();

  /// Retrieves metadata for all saved boards, sorted by `updatedAt` descending.
  Future<List<BoardMetadata>> getBoards();

  /// Retrieves metadata for a specific board ID. Returns null if not found.
  Future<BoardMetadata?> getBoardMetadata(String boardId);

  /// Retrieves the visual canvas layout data for a specific board ID.
  Future<CanvasData?> getCanvasData(String boardId);

  /// Saves or updates both metadata and canvas data atomically.
  Future<void> saveBoard({
    required BoardMetadata metadata,
    required CanvasData canvasData,
  });

  /// Updates only the board metadata (e.g., renaming a board).
  Future<void> updateMetadata(BoardMetadata metadata);

  /// Updates only the canvas data (e.g., during active debounced autosave).
  Future<void> updateCanvasData(CanvasData canvasData);

  /// Permanently deletes a board and its canvas layout.
  Future<void> deleteBoard(String boardId);

  /// Duplicates a board, generating a new board ID and cloning all cards.
  Future<BoardMetadata> duplicateBoard({
    required String sourceBoardId,
    required String newTitle,
  });
}
