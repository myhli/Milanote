import 'package:flutter/foundation.dart';

/// Schema manifest contained inside every `.board` archive file (US-011 & PKG-01).
/// Validates package integrity, version compatibility, and metadata before extraction.
@immutable
class BoardBundleManifest {
  static const String currentSchemaVersion = '1.0.0';
  static const String currentAppName = 'LocalBoard';

  final String schemaVersion;
  final String appName;
  final DateTime exportDate;
  final String boardId;
  final String title;
  final int cardCount;
  final int arrowCount;
  final int assetCount;
  final List<String> assetList;

  const BoardBundleManifest({
    this.schemaVersion = currentSchemaVersion,
    this.appName = currentAppName,
    required this.exportDate,
    required this.boardId,
    required this.title,
    required this.cardCount,
    this.arrowCount = 0,
    this.assetCount = 0,
    this.assetList = const [],
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'appName': appName,
        'exportDate': exportDate.toIso8601String(),
        'boardId': boardId,
        'title': title,
        'cardCount': cardCount,
        'arrowCount': arrowCount,
        'assetCount': assetCount,
        'assetList': assetList,
      };

  factory BoardBundleManifest.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assetList'] as List<dynamic>? ?? [];
    return BoardBundleManifest(
      schemaVersion: json['schemaVersion'] as String? ?? currentSchemaVersion,
      appName: json['appName'] as String? ?? currentAppName,
      exportDate: json['exportDate'] != null
          ? DateTime.parse(json['exportDate'] as String)
          : DateTime.now(),
      boardId: json['boardId'] as String? ?? '',
      title: json['title'] as String? ?? 'Papan Tanpa Judul',
      cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
      arrowCount: (json['arrowCount'] as num?)?.toInt() ?? 0,
      assetCount: (json['assetCount'] as num?)?.toInt() ?? 0,
      assetList: rawAssets.map((e) => e.toString()).toList(),
    );
  }

  /// Validates raw JSON map. Returns null if valid, or a friendly error message if invalid.
  static String? validate(Map<String, dynamic> json) {
    if (!json.containsKey('schemaVersion') || !json.containsKey('boardId')) {
      return 'Format berkas .board tidak dikenali (manifest.json tidak lengkap).';
    }

    final app = json['appName'] as String?;
    if (app != null && app != currentAppName) {
      return 'Berkas ini dibuat oleh aplikasi lain ($app).';
    }

    final version = json['schemaVersion'] as String?;
    if (version == null || !version.startsWith('1.')) {
      return 'Versi berkas ($version) tidak didukung oleh versi LocalBoard ini.';
    }

    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardBundleManifest &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          appName == other.appName &&
          boardId == other.boardId &&
          title == other.title &&
          cardCount == other.cardCount &&
          arrowCount == other.arrowCount &&
          assetCount == other.assetCount &&
          listEquals(assetList, other.assetList);

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        appName,
        boardId,
        title,
        cardCount,
        arrowCount,
        assetCount,
        Object.hashAll(assetList),
      );
}
