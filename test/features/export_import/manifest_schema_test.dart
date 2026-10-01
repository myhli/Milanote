import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/export_import/board_bundle/manifest_schema.dart';

void main() {
  group('BoardBundleManifest Tests (PKG-01)', () {
    test('toJson and fromJson serialization works accurately', () {
      final now = DateTime.now();
      final manifest = BoardBundleManifest(
        schemaVersion: '1.0.0',
        appName: 'LocalBoard',
        exportDate: now,
        boardId: 'board_test_123',
        title: 'Karakter Anime Fantasi',
        cardCount: 12,
        arrowCount: 4,
        assetCount: 3,
        assetList: const ['assets/img1.png', 'assets/img2.jpg', 'assets/cover.webp'],
      );

      final json = manifest.toJson();
      expect(json['schemaVersion'], '1.0.0');
      expect(json['appName'], 'LocalBoard');
      expect(json['boardId'], 'board_test_123');
      expect(json['title'], 'Karakter Anime Fantasi');
      expect(json['cardCount'], 12);
      expect(json['arrowCount'], 4);
      expect(json['assetCount'], 3);
      expect(json['assetList'], hasLength(3));

      final restored = BoardBundleManifest.fromJson(json);
      expect(restored.schemaVersion, manifest.schemaVersion);
      expect(restored.appName, manifest.appName);
      expect(restored.boardId, manifest.boardId);
      expect(restored.title, manifest.title);
      expect(restored.cardCount, manifest.cardCount);
      expect(restored.assetList, manifest.assetList);
    });

    test('validate returns null for valid manifest and error message for corrupt data', () {
      final validMap = {
        'schemaVersion': '1.0.0',
        'appName': 'LocalBoard',
        'boardId': 'b1',
        'title': 'Test',
      };
      expect(BoardBundleManifest.validate(validMap), isNull);

      final missingId = {
        'schemaVersion': '1.0.0',
        'title': 'Test',
      };
      expect(BoardBundleManifest.validate(missingId), contains('tidak lengkap'));

      final foreignApp = {
        'schemaVersion': '1.0.0',
        'appName': 'ForeignApp',
        'boardId': 'b1',
      };
      expect(BoardBundleManifest.validate(foreignApp), contains('aplikasi lain'));

      final unsupportedVer = {
        'schemaVersion': '2.0.0',
        'appName': 'LocalBoard',
        'boardId': 'b1',
      };
      expect(BoardBundleManifest.validate(unsupportedVer), contains('tidak didukung'));
    });
  });
}
