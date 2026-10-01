import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/gallery/presentation/gallery_screen.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/board_repository.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';
import 'package:localboard/features/storage/storage_providers.dart';

class MockGalleryBoardRepository implements BoardRepository {
  final List<BoardMetadata> boards = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<BoardMetadata>> getBoards() async => List.unmodifiable(boards);

  @override
  Future<BoardMetadata?> getBoardMetadata(String boardId) async {
    try {
      return boards.firstWhere((b) => b.id == boardId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CanvasData?> getCanvasData(String boardId) async => null;

  @override
  Future<void> saveBoard({
    required BoardMetadata metadata,
    required CanvasData canvasData,
  }) async {
    boards.removeWhere((b) => b.id == metadata.id);
    boards.add(metadata);
  }

  @override
  Future<void> updateMetadata(BoardMetadata metadata) async {
    final idx = boards.indexWhere((b) => b.id == metadata.id);
    if (idx != -1) boards[idx] = metadata;
  }

  @override
  Future<void> updateCanvasData(CanvasData canvasData) async {}

  @override
  Future<void> deleteBoard(String boardId) async {
    boards.removeWhere((b) => b.id == boardId);
  }

  @override
  Future<BoardMetadata> duplicateBoard({
    required String sourceBoardId,
    required String newTitle,
  }) async {
    final dup = BoardMetadata(
      id: 'dup_$sourceBoardId',
      title: newTitle,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    boards.add(dup);
    return dup;
  }
}

void main() {
  group('GalleryScreen Tests (GAL-01 & GAL-03)', () {
    late MockGalleryBoardRepository mockRepo;

    setUp(() {
      mockRepo = MockGalleryBoardRepository();
    });

    testWidgets('renders empty state when no boards exist', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LocalBoard'), findsOneWidget);
      expect(find.text('Galeri Papan Studio'), findsOneWidget);
      expect(find.text('Belum Ada Papan Proyek'), findsOneWidget);
      expect(find.text('Buat Papan Baru'), findsWidgets);
      expect(find.text('Gunakan Template'), findsWidgets);
    });

    testWidgets('renders boards and performs search filtering', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      mockRepo.boards.addAll([
        BoardMetadata(
          id: 'b1',
          title: 'Konsep Desain Cyberpunk',
          createdAt: now,
          updatedAt: now,
          cardCount: 4,
        ),
        BoardMetadata(
          id: 'b2',
          title: 'Ilustrasi Dongeng Nusantara',
          createdAt: now,
          updatedAt: now,
          cardCount: 8,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Konsep Desain Cyberpunk'), findsOneWidget);
      expect(find.text('Ilustrasi Dongeng Nusantara'), findsOneWidget);

      // Filter by searching
      await tester.enterText(find.byType(TextField), 'Cyberpunk');
      await tester.pumpAndSettle();

      expect(find.text('Konsep Desain Cyberpunk'), findsOneWidget);
      expect(find.text('Ilustrasi Dongeng Nusantara'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Konsep Desain Cyberpunk'), findsOneWidget);
      expect(find.text('Ilustrasi Dongeng Nusantara'), findsOneWidget);
    });

    testWidgets('clicking Gunakan Template opens template selection modal', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Gunakan Template'
      await tester.tap(find.text('Gunakan Template'));
      await tester.pumpAndSettle();

      // Verify modal opened
      expect(find.text('Pilih Template Seni Studio'), findsOneWidget);
      expect(find.text('Moodboard Karakter'), findsOneWidget);
      expect(find.text('Studi Gaya & Warna'), findsOneWidget);
      expect(find.text('Storyboard 6-Panel'), findsOneWidget);
      expect(find.text('Brainstorming Proyek'), findsOneWidget);
    });
  });
}
