import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../storage/data/asset_manager.dart';
import '../../storage/domain/board_metadata.dart';
import '../../storage/domain/board_repository.dart';
import '../../storage/domain/canvas_data.dart';
import 'manifest_schema.dart';

/// Service responsible for packaging and unpacking standalone `.board` bundle files (US-011, FR-14, FR-15, PKG-02).
/// Packs canvas JSON schema, manifest metadata, and all offline assets into a compressed ZIP container.
class BoardBundleService {
  final BoardRepository repository;
  final AssetManager assetManager;

  BoardBundleService({
    required this.repository,
    required this.assetManager,
  });

  /// Creates a standalone `.board` ZIP byte buffer containing manifest.json,
  /// canvas_data.json, and all referenced image assets.
  Future<Uint8List> createBundleBytes({
    required BoardMetadata metadata,
    required CanvasData canvasData,
  }) async {
    final archive = Archive();
    final assetList = <String>[];

    // 1. Collect all asset files referenced by ImageCards and LinkCards
    final referencedAssets = <String>{};
    for (final cardMap in canvasData.cards) {
      final type = cardMap['type'] as String?;
      if (type == 'image') {
        final assetUuid = cardMap['assetUuid'] as String?;
        if (assetUuid != null && assetUuid.isNotEmpty) {
          referencedAssets.add(assetUuid);
        }
      } else if (type == 'link') {
        final coverUuid = cardMap['coverAssetUuid'] as String?;
        if (coverUuid != null && coverUuid.isNotEmpty) {
          referencedAssets.add(coverUuid);
        }
      }
    }

    // 2. Read each asset file and bundle into 'assets/' in archive
    for (final relPath in referencedAssets) {
      final file = await assetManager.getAssetFile(
        boardId: metadata.id,
        relativePath: relPath,
      );

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final filename = relPath.split('/').last;
        final archivePath = 'assets/$filename';
        archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
        assetList.add(archivePath);
      }
    }

    // 3. Create and pack manifest.json
    final manifest = BoardBundleManifest(
      exportDate: DateTime.now(),
      boardId: metadata.id,
      title: metadata.title,
      cardCount: canvasData.cards.length,
      arrowCount: canvasData.arrows.length,
      assetCount: assetList.length,
      assetList: assetList,
    );

    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // 4. Pack canvas_data.json
    final canvasBytes = utf8.encode(jsonEncode(canvasData.toJson()));
    archive.addFile(ArchiveFile('canvas_data.json', canvasBytes.length, canvasBytes));

    // 5. Compress into ZIP archive
    final zipEncoder = ZipEncoder();
    final encoded = zipEncoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Exports board to a chosen `.board` file location via the OS save file picker dialog.
  Future<String?> exportBoardToFile(String boardId) async {
    final meta = await repository.getBoardMetadata(boardId);
    final canvas = await repository.getCanvasData(boardId);

    if (meta == null || canvas == null) {
      throw Exception('Data papan tidak ditemukan.');
    }

    final bytes = await createBundleBytes(
      metadata: meta,
      canvasData: canvas,
    );

    final sanitizedTitle = meta.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\u00A0-\uFFFF-]'), '_');
    final defaultFileName = '$sanitizedTitle.board';

    final result = await FilePicker.saveFile(
      dialogTitle: 'Simpan Berkas Proyek LocalBoard (.board)',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['board', 'zip'],
      bytes: bytes,
    );

    if (result != null) {
      return result.path.isNotEmpty ? result.path : result.toString();
    }

    return null;
  }

  /// Imports a `.board` archive from raw bytes, extracting assets to the local sandbox
  /// and persisting board metadata and cards into the local database.
  Future<BoardMetadata> importBundleBytes({
    required Uint8List bundleBytes,
    String? customTitle,
  }) async {
    final zipDecoder = ZipDecoder();
    final archive = zipDecoder.decodeBytes(bundleBytes);

    // 1. Locate and validate manifest.json & canvas_data.json
    ArchiveFile? manifestFile;
    ArchiveFile? canvasFile;

    for (final file in archive) {
      if (file.name == 'manifest.json') {
        manifestFile = file;
      } else if (file.name == 'canvas_data.json') {
        canvasFile = file;
      }
    }

    if (manifestFile == null || canvasFile == null) {
      throw const FormatException(
        'Berkas .board tidak valid: berkas manifest.json atau canvas_data.json tidak ditemukan.',
      );
    }

    final manifestMap = jsonDecode(utf8.decode(manifestFile.content as List<int>))
        as Map<String, dynamic>;

    final validationError = BoardBundleManifest.validate(manifestMap);
    if (validationError != null) {
      throw FormatException(validationError);
    }

    final manifest = BoardBundleManifest.fromJson(manifestMap);

    // 2. Generate brand new unique board ID to prevent collisions
    final newBoardId = 'board_${const Uuid().v4()}';
    final oldToNewAssetMap = <String, String>{};

    // 3. Extract and save all assets to the local app sandbox
    for (final file in archive) {
      if (file.name.startsWith('assets/') && file.isFile) {
        final content = file.content as List<int>;
        final fileName = file.name.split('/').last;
        final ext = fileName.contains('.') ? fileName.split('.').last : 'png';

        final savedPath = await assetManager.saveAsset(
          boardId: newBoardId,
          bytes: Uint8List.fromList(content),
          fileExtension: ext,
        );

        oldToNewAssetMap[file.name] = savedPath;
        // Also map just the relative path if stored as 'assets/<uuid>.<ext>'
        oldToNewAssetMap['assets/$fileName'] = savedPath;
      }
    }

    // 4. Parse canvas data and remap asset paths to new sandbox locations
    final canvasMap = jsonDecode(utf8.decode(canvasFile.content as List<int>))
        as Map<String, dynamic>;

    final rawCards = canvasMap['cards'] as List<dynamic>? ?? [];
    final remappedCards = <Map<String, dynamic>>[];

    for (final item in rawCards) {
      final card = Map<String, dynamic>.from(item as Map);
      final type = card['type'] as String?;

      if (type == 'image') {
        final oldUuid = card['assetUuid'] as String?;
        if (oldUuid != null && oldToNewAssetMap.containsKey(oldUuid)) {
          card['assetUuid'] = oldToNewAssetMap[oldUuid];
        }
      } else if (type == 'link') {
        final oldCover = card['coverAssetUuid'] as String?;
        if (oldCover != null && oldToNewAssetMap.containsKey(oldCover)) {
          card['coverAssetUuid'] = oldToNewAssetMap[oldCover];
        }
      }

      remappedCards.add(card);
    }

    final rawArrows = canvasMap['arrows'] as List<dynamic>? ?? [];
    final arrowsList = rawArrows.map((a) => Map<String, dynamic>.from(a as Map)).toList();

    final now = DateTime.now();
    final newMetadata = BoardMetadata(
      id: newBoardId,
      title: customTitle ?? '${manifest.title} (Impor)',
      createdAt: now,
      updatedAt: now,
      cardCount: remappedCards.length,
    );

    final newCanvasData = CanvasData(
      boardId: newBoardId,
      cards: remappedCards,
      arrows: arrowsList,
      updatedAt: now,
    );

    await repository.saveBoard(
      metadata: newMetadata,
      canvasData: newCanvasData,
    );

    return newMetadata;
  }

  /// Prompts user to select a `.board` file and imports it into the local gallery.
  Future<BoardMetadata?> pickAndImportBoard() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Pilih Berkas Proyek LocalBoard (.board)',
      type: FileType.custom,
      allowedExtensions: ['board', 'zip'],
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final bytes = await file.readAsBytes();
      return importBundleBytes(
        bundleBytes: bytes,
        customTitle: file.name.replaceAll(RegExp(r'\.(board|zip)$'), ''),
      );
    }

    return null;
  }
}
