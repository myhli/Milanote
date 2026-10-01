import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Local Asset Manager responsible for securely copying, storing, and referencing
/// art student media assets (images, cover thumbnails) in the local sandbox.
/// All stored paths are relative (e.g., 'assets/asset-uuid.png') to ensure 100%
/// portability across macOS, Windows, Linux, and Mobile.
class AssetManager {
  final Future<Directory> Function()? baseDirProvider;
  final Uuid _uuid;

  AssetManager({
    this.baseDirProvider,
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid();

  /// Returns the base directory where board assets are sandboxed.
  Future<Directory> getBaseDir() async {
    if (baseDirProvider != null) {
      return baseDirProvider!();
    }
    return getApplicationDocumentsDirectory();
  }

  /// Returns the directory for a specific board's assets: `<base>/boards/<boardId>/assets`
  Future<Directory> getBoardAssetsDir(String boardId) async {
    final base = await getBaseDir();
    final dir = Directory('${base.path}/boards/$boardId/assets');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Saves raw image bytes into the board's asset sandbox.
  /// Returns the relative asset identifier (e.g., 'assets/550e8400-e29b-41d4-a716-446655440000.png').
  Future<String> saveAsset({
    required String boardId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final cleanExt = fileExtension.replaceAll('.', '').toLowerCase();
    final assetFileName = '${_uuid.v4()}.$cleanExt';
    final assetsDir = await getBoardAssetsDir(boardId);
    final targetFile = File('${assetsDir.path}/$assetFileName');

    await targetFile.writeAsBytes(bytes, flush: true);
    return 'assets/$assetFileName';
  }

  /// Resolves a relative asset path into an absolute file system path.
  Future<String> resolveAssetPath({
    required String boardId,
    required String relativePath,
  }) async {
    final fileName = relativePath.split('/').last;
    final assetsDir = await getBoardAssetsDir(boardId);
    return '${assetsDir.path}/$fileName';
  }

  /// Returns a File handle for an asset in the board sandbox.
  Future<File> getAssetFile({
    required String boardId,
    required String relativePath,
  }) async {
    final path = await resolveAssetPath(boardId: boardId, relativePath: relativePath);
    return File(path);
  }

  /// Reads raw bytes for an asset. Returns null if file does not exist.
  Future<Uint8List?> getAssetBytes({
    required String boardId,
    required String relativePath,
  }) async {
    try {
      final absolutePath = await resolveAssetPath(
        boardId: boardId,
        relativePath: relativePath,
      );
      final file = File(absolutePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('AssetManager.getAssetBytes error: $e');
    }
    return null;
  }

  /// Deletes a specific asset from disk.
  Future<bool> deleteAsset({
    required String boardId,
    required String relativePath,
  }) async {
    try {
      final absolutePath = await resolveAssetPath(
        boardId: boardId,
        relativePath: relativePath,
      );
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('AssetManager.deleteAsset error: $e');
    }
    return false;
  }

  /// Deletes the entire assets folder for a board (used when deleting a board).
  Future<void> deleteBoardAssets(String boardId) async {
    try {
      final base = await getBaseDir();
      final boardDir = Directory('${base.path}/boards/$boardId');
      if (await boardDir.exists()) {
        await boardDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('AssetManager.deleteBoardAssets error: $e');
    }
  }

  /// Lists all relative asset filenames currently saved for a board.
  Future<List<String>> listBoardAssets(String boardId) async {
    final assetsDir = await getBoardAssetsDir(boardId);
    if (!await assetsDir.exists()) return [];

    final entities = await assetsDir.list().toList();
    final relativePaths = <String>[];
    for (final entity in entities) {
      if (entity is File) {
        final fileName = entity.uri.pathSegments.last;
        if (fileName.isNotEmpty) {
          relativePaths.add('assets/$fileName');
        }
      }
    }
    return relativePaths;
  }
}
