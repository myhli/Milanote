import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/app/app.dart';
import 'package:localboard/features/canvas/controller/board_state_notifier.dart';
import 'package:localboard/features/cards/models/image_card.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/widgets/card_wrapper.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/board_repository.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';
import 'package:localboard/features/storage/storage_providers.dart';

class _FakeBoardRepository implements BoardRepository {
  final Map<String, BoardMetadata> metadataStore = {};
  final Map<String, CanvasData> canvasStore = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<BoardMetadata>> getBoards() async => metadataStore.values.toList();

  @override
  Future<BoardMetadata?> getBoardMetadata(String boardId) async =>
      metadataStore[boardId];

  @override
  Future<CanvasData?> getCanvasData(String boardId) async =>
      canvasStore[boardId];

  @override
  Future<void> saveBoard({
    required BoardMetadata metadata,
    required CanvasData canvasData,
  }) async {
    metadataStore[metadata.id] = metadata;
    canvasStore[metadata.id] = canvasData;
  }

  @override
  Future<void> updateMetadata(BoardMetadata metadata) async {
    metadataStore[metadata.id] = metadata;
  }

  @override
  Future<void> updateCanvasData(CanvasData canvasData) async {
    canvasStore[canvasData.boardId] = canvasData;
  }

  @override
  Future<void> deleteBoard(String boardId) async {
    metadataStore.remove(boardId);
    canvasStore.remove(boardId);
  }

  @override
  Future<BoardMetadata> duplicateBoard({
    required String sourceBoardId,
    required String newTitle,
  }) async {
    final newId = 'dup_$sourceBoardId';
    final meta = BoardMetadata(
      id: newId,
      title: newTitle,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      cardCount: 0,
    );
    metadataStore[newId] = meta;
    canvasStore[newId] = CanvasData(
      boardId: newId,
      cards: const [],
      arrows: const [],
      updatedAt: DateTime.now(),
    );
    return meta;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 5 Canvas Interactions & Shortcut Tests', () {
    late _FakeBoardRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeBoardRepository();
    });

    testWidgets('Dragging a card records MoveCardAction and supports Undo / Redo',
        (tester) async {
      const boardId = 'test_move_undo_board';
      final now = DateTime.now();

      final initialCard = NoteCard(
        id: 'test_card_1',
        x: 250,
        y: 250,
        width: 200,
        height: 150,
        title: 'Movable Card',
        createdAt: now,
        updatedAt: now,
      );

      final meta = BoardMetadata(
        id: boardId,
        title: 'Test Board',
        createdAt: now,
        updatedAt: now,
        cardCount: 1,
      );
      final canvas = CanvasData(
        boardId: boardId,
        cards: [initialCard.toJson()],
        arrows: const [],
        updatedAt: now,
      );
      await fakeRepo.saveBoard(metadata: meta, canvasData: canvas);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: BoardCanvasScreen(boardId: boardId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card is displayed at initial position
      expect(find.text('Movable Card'), findsOneWidget);

      final dragGrip = find.byKey(const Key('note_card_drag_handle'));
      expect(dragGrip, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(dragGrip));
      await gesture.moveBy(const Offset(40, 30));
      await gesture.moveBy(const Offset(40, 30));
      await gesture.up();
      await tester.pumpAndSettle();

      // Get container context to read state
      final element = tester.element(find.byType(BoardCanvasScreen));
      final container = ProviderScope.containerOf(element);
      final movedCard = container
          .read(boardStateNotifierProvider)
          .cards
          .firstWhere((c) => c.id == 'test_card_1');

      expect(movedCard.x, greaterThan(250));
      expect(movedCard.y, greaterThan(250));
      expect(container.read(boardStateNotifierProvider).canUndo, isTrue);

      // Trigger Undo
      container.read(boardStateNotifierProvider.notifier).undo();
      await tester.pumpAndSettle();

      final undoneCard = container
          .read(boardStateNotifierProvider)
          .cards
          .firstWhere((c) => c.id == 'test_card_1');
      expect(undoneCard.x, closeTo(250.0, 0.001));
      expect(undoneCard.y, closeTo(250.0, 0.001));
      expect(container.read(boardStateNotifierProvider).canRedo, isTrue);

      // Trigger Redo
      container.read(boardStateNotifierProvider.notifier).redo();
      await tester.pumpAndSettle();

      final redoneCard = container
          .read(boardStateNotifierProvider)
          .cards
          .firstWhere((c) => c.id == 'test_card_1');
      expect(redoneCard.x, closeTo(movedCard.x, 0.001));
      expect(redoneCard.y, closeTo(movedCard.y, 0.001));
    });

    testWidgets('Resizing a card records ResizeCardAction and supports Undo',
        (tester) async {
      const boardId = 'test_resize_undo_board';
      final now = DateTime.now();

      final initialCard = NoteCard(
        id: 'test_card_2',
        x: 250,
        y: 250,
        width: 200,
        height: 150,
        title: 'Resizable Card',
        createdAt: now,
        updatedAt: now,
      );

      await fakeRepo.saveBoard(
        metadata: BoardMetadata(
          id: boardId,
          title: 'Resize Board',
          createdAt: now,
          updatedAt: now,
          cardCount: 1,
        ),
        canvasData: CanvasData(
          boardId: boardId,
          cards: [initialCard.toJson()],
          arrows: const [],
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: BoardCanvasScreen(boardId: boardId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap drag handle to select the card so resize handle appears
      final dragGrip = find.byKey(const Key('note_card_drag_handle'));
      expect(dragGrip, findsOneWidget);
      await tester.tap(dragGrip);
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(BoardCanvasScreen));
      final container = ProviderScope.containerOf(element);

      final resizeHandle = find.byKey(const Key('card_resize_handle'));
      expect(resizeHandle, findsOneWidget);

      // Drag resize handle
      await tester.drag(resizeHandle, const Offset(60, 40));
      await tester.pumpAndSettle();

      final resizedCard = container
          .read(boardStateNotifierProvider)
          .cards
          .firstWhere((c) => c.id == 'test_card_2');

      expect(resizedCard.width, greaterThan(200));
      expect(resizedCard.height, greaterThan(150));
      expect(container.read(boardStateNotifierProvider).canUndo, isTrue);

      // Undo resize
      container.read(boardStateNotifierProvider.notifier).undo();
      await tester.pumpAndSettle();

      final restoredCard = container
          .read(boardStateNotifierProvider)
          .cards
          .firstWhere((c) => c.id == 'test_card_2');

      expect(restoredCard.width, closeTo(200.0, 0.001));
      expect(restoredCard.height, closeTo(150.0, 0.001));
    });

    testWidgets('ImageCard proportional resizing maintains aspect ratio (US-005)',
        (tester) async {
      final imageCard = ImageCard(
        id: 'img-ratio-1',
        x: 100,
        y: 100,
        width: 320,
        height: 240, // 4:3 aspect ratio (1.333)
        assetUuid: 'sample_asset_uuid',
        caption: 'Aspect Ratio Image',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      double? finalW, finalH;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CardWrapper(
                  card: imageCard,
                  isSelected: true,
                  canvasScale: 1.0,
                  onResize: (w, h) {
                    finalW = w;
                    finalH = h;
                  },
                  child: const Text('Image Preview'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('card_resize_handle')), findsOneWidget);

      // Drag resize handle outward
      await tester.drag(
        find.byKey(const Key('card_resize_handle')),
        const Offset(64, 48),
      );
      await tester.pump();

      expect(finalW, isNotNull);
      expect(finalH, isNotNull);

      // Initial aspect ratio: 320 / 240 = 1.3333333333333333
      final initialRatio = 320.0 / 240.0;
      final newRatio = finalW! / finalH!;
      expect(newRatio, closeTo(initialRatio, 0.01));
    });

    testWidgets('Double-tapping empty canvas creates quick note card (PRD US-004)',
        (tester) async {
      const boardId = 'test_double_tap_board';
      final now = DateTime.now();

      await fakeRepo.saveBoard(
        metadata: BoardMetadata(
          id: boardId,
          title: 'Empty Canvas Board',
          createdAt: now,
          updatedAt: now,
          cardCount: 0,
        ),
        canvasData: CanvasData(
          boardId: boardId,
          cards: const [],
          arrows: const [],
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: BoardCanvasScreen(boardId: boardId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final element = tester.element(find.byType(BoardCanvasScreen));
      final container = ProviderScope.containerOf(element);

      expect(container.read(boardStateNotifierProvider).cards.isEmpty, isTrue);

      // Double-tap at center of screen
      await tester.tapAt(const Offset(400, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(400, 300));
      await tester.pumpAndSettle();

      // Card created
      final cards = container.read(boardStateNotifierProvider).cards;
      expect(cards.length, equals(1));
      expect(cards.first, isA<NoteCard>());
      expect((cards.first as NoteCard).title, equals('Catatan Cepat'));
    });

    testWidgets('Keyboard shortcut Escape deselects card and cancels arrow mode',
        (tester) async {
      const boardId = 'test_escape_board';
      final now = DateTime.now();

      final initialCard = NoteCard(
        id: 'test_card_esc',
        x: 100,
        y: 100,
        width: 200,
        height: 150,
        title: 'Esc Card',
        createdAt: now,
        updatedAt: now,
      );

      await fakeRepo.saveBoard(
        metadata: BoardMetadata(
          id: boardId,
          title: 'Escape Board',
          createdAt: now,
          updatedAt: now,
          cardCount: 1,
        ),
        canvasData: CanvasData(
          boardId: boardId,
          cards: [initialCard.toJson()],
          arrows: const [],
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: BoardCanvasScreen(boardId: boardId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final element = tester.element(find.byType(BoardCanvasScreen));
      final container = ProviderScope.containerOf(element);
      final notifier = container.read(boardStateNotifierProvider.notifier);

      notifier.selectCard('test_card_esc');
      notifier.setArrowMode(true);
      await tester.pumpAndSettle();

      expect(container.read(boardStateNotifierProvider).selectedCardId,
          equals('test_card_esc'));
      expect(container.read(boardStateNotifierProvider).isArrowMode, isTrue);

      // Send Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(
          container.read(boardStateNotifierProvider).selectedCardId, isNull);
      expect(container.read(boardStateNotifierProvider).isArrowMode, isFalse);
    });
  });
}
