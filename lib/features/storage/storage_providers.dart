import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/asset_manager.dart';
import 'data/hive_board_repository.dart';
import 'domain/board_metadata.dart';
import 'domain/board_repository.dart';
import '../export_import/board_bundle/board_bundle_service.dart';

/// Provider for AssetManager instance.
final assetManagerProvider = Provider<AssetManager>((ref) {
  return AssetManager();
});

/// Provider for BoardRepository instance.
final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  final assetManager = ref.watch(assetManagerProvider);
  return HiveBoardRepository(assetManager: assetManager);
});

/// Provider for BoardBundleService (.board packaging & extraction).
final boardBundleServiceProvider = Provider<BoardBundleService>((ref) {
  final repo = ref.watch(boardRepositoryProvider);
  final assetManager = ref.watch(assetManagerProvider);
  return BoardBundleService(repository: repo, assetManager: assetManager);
});

/// Async notifier for managing the list of boards displayed in the gallery.
class BoardsListNotifier extends AsyncNotifier<List<BoardMetadata>> {
  @override
  Future<List<BoardMetadata>> build() async {
    final repository = ref.watch(boardRepositoryProvider);
    return repository.getBoards();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(boardRepositoryProvider);
      return repository.getBoards();
    });
  }

  Future<void> deleteBoard(String boardId) async {
    final repository = ref.read(boardRepositoryProvider);
    await repository.deleteBoard(boardId);
    await refresh();
  }

  Future<BoardMetadata> duplicateBoard(String sourceBoardId, String newTitle) async {
    final repository = ref.read(boardRepositoryProvider);
    final duplicated = await repository.duplicateBoard(
      sourceBoardId: sourceBoardId,
      newTitle: newTitle,
    );
    await refresh();
    return duplicated;
  }
}

final boardsListProvider =
    AsyncNotifierProvider<BoardsListNotifier, List<BoardMetadata>>(() {
  return BoardsListNotifier();
});
