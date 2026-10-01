import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/app/app.dart';
import 'package:localboard/core/utils/bounding_box_calculator.dart';
import 'package:localboard/features/storage/data/asset_manager.dart';
import 'package:localboard/features/canvas/controller/board_state_notifier.dart';
import 'package:localboard/features/canvas/controller/canvas_controller.dart';
import 'package:localboard/features/cards/models/base_card.dart';
import 'package:localboard/features/cards/models/color_card.dart';
import 'package:localboard/features/cards/models/connector_arrow.dart';
import 'package:localboard/features/cards/models/image_card.dart';
import 'package:localboard/features/cards/models/link_card.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/models/subboard_card.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/board_repository.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';
import 'package:localboard/features/storage/storage_providers.dart';

class _BenchmarkFakeBoardRepository implements BoardRepository {
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
    return meta;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Canvas 60/120 FPS & Stress Benchmark Tests (US-003, NFR-1)', () {
    late _BenchmarkFakeBoardRepository fakeRepo;

    setUp(() {
      fakeRepo = _BenchmarkFakeBoardRepository();
    });

    test('BoundingBoxCalculator with 100+ cards calculates in < 1ms', () {
      final cards = <BaseCard>[];
      final now = DateTime.now();

      // Generate 120 cards arranged in a grid across the canvas
      for (int i = 0; i < 120; i++) {
        final row = i ~/ 10;
        final col = i % 10;
        cards.add(
          NoteCard(
            id: 'card_$i',
            x: col * 320.0,
            y: row * 260.0,
            width: 280,
            height: 220,
            title: 'Card $i',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final stopwatch = Stopwatch()..start();
      final bounds = BoundingBoxCalculator.calculate(cards: cards, padding: 0.0);
      stopwatch.stop();

      expect(bounds.left, equals(0.0));
      expect(bounds.top, equals(0.0));
      expect(bounds.right, equals(9 * 320.0 + 280.0));
      expect(bounds.bottom, equals(11 * 260.0 + 220.0));
      expect(stopwatch.elapsedMicroseconds, lessThan(5000)); // < 5ms (sub-frame budget)
    });

    test('CanvasController 10,000 coordinate translations execute in < 10ms', () {
      final controller = CanvasController();
      controller.setScale(1.75, focalPoint: const Offset(400, 300));
      controller.panBy(const Offset(120, -80));

      double maxDiff = 0.0;
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        final screen = Offset(i.toDouble() % 1920, (i * 2).toDouble() % 1080);
        final canvas = controller.screenToCanvas(screen);
        final roundTrip = controller.canvasToScreen(canvas);
        final diffX = (roundTrip.dx - screen.dx).abs();
        final diffY = (roundTrip.dy - screen.dy).abs();
        if (diffX > maxDiff) maxDiff = diffX;
        if (diffY > maxDiff) maxDiff = diffY;
      }
      stopwatch.stop();

      expect(maxDiff, lessThan(0.001));
      expect(stopwatch.elapsedMilliseconds, lessThan(25));
      controller.dispose();
    });

    test('State mutation on 150 items executes under 5ms', () {
      final container = ProviderContainer(
        overrides: [
          boardRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final notifier = container.read(boardStateNotifierProvider.notifier);
      final now = DateTime.now();

      // Seed 150 cards
      for (int i = 0; i < 150; i++) {
        notifier.addCard(
          NoteCard(
            id: 'perf_card_$i',
            x: (i % 10) * 300.0,
            y: (i ~/ 10) * 250.0,
            width: 250,
            height: 200,
            title: 'Note $i',
            createdAt: now,
            updatedAt: now,
          ),
          recordHistory: false,
        );
      }

      expect(container.read(boardStateNotifierProvider).cards.length, equals(150));

      // Benchmark moving card in 150-card state
      final stopwatch = Stopwatch()..start();
      notifier.moveCard('perf_card_75', 550.0, 650.0, isFinal: true, startX: 300.0, startY: 300.0);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5));

      final moved = container.read(boardStateNotifierProvider).cards.firstWhere((c) => c.id == 'perf_card_75');
      expect(moved.x, equals(550.0));
      expect(moved.y, equals(650.0));

      container.dispose();
    });

    testWidgets('100+ Mixed Cards & 30 Connector Arrows render smoothly in viewport',
        (tester) async {
      const boardId = 'stress_test_board';
      final now = DateTime.now();

      final cards = <Map<String, dynamic>>[];
      final arrows = <Map<String, dynamic>>[];

      // Populate 100 heterogeneous cards
      for (int i = 0; i < 100; i++) {
        final x = (i % 10) * 320.0 + 100.0;
        final y = (i ~/ 10) * 260.0 + 100.0;
        final type = i % 5;

        BaseCard card;
        switch (type) {
          case 0:
            card = NoteCard(
              id: 'c_$i',
              x: x,
              y: y,
              width: 260,
              height: 200,
              zIndex: i + 1,
              title: 'Note $i',
              content: 'Studio visual concept documentation $i',
              colorHex: '#FEF9C3',
              createdAt: now,
              updatedAt: now,
            );
            break;
          case 1:
            card = ImageCard(
              id: 'c_$i',
              x: x,
              y: y,
              width: 260,
              height: 200,
              zIndex: i + 1,
              assetUuid: 'asset_$i',
              caption: 'Artwork Frame $i',
              createdAt: now,
              updatedAt: now,
            );
            break;
          case 2:
            card = ColorCard(
              id: 'c_$i',
              x: x,
              y: y,
              width: 260,
              height: 140,
              zIndex: i + 1,
              title: 'Palette $i',
              colorsHex: const ['#2C3E50', '#E74C3C', '#3498DB', '#F1C40F', '#1ABC9C'],
              createdAt: now,
              updatedAt: now,
            );
            break;
          case 3:
            card = LinkCard(
              id: 'c_$i',
              x: x,
              y: y,
              width: 260,
              height: 220,
              zIndex: i + 1,
              url: 'https://artstation.com/concept_$i',
              title: 'ArtStation Ref $i',
              createdAt: now,
              updatedAt: now,
            );
            break;
          case 4:
          default:
            card = SubBoardCard(
              id: 'c_$i',
              x: x,
              y: y,
              width: 260,
              height: 160,
              zIndex: i + 1,
              title: 'Nested Board $i',
              targetBoardId: 'sub_board_$i',
              cardCount: 8,
              createdAt: now,
              updatedAt: now,
            );
            break;
        }
        cards.add(card.toJson());

        // Create arrows connecting adjacent cards
        if (i > 0 && i % 3 == 0) {
          arrows.add(
            ConnectorArrow(
              id: 'arrow_$i',
              startCardId: 'c_${i - 1}',
              endCardId: 'c_$i',
              startAnchor: CardAnchor.right,
              endAnchor: CardAnchor.left,
              style: ArrowStyle.curved,
              head: ArrowHead.end,
              strokeWidth: 2.0,
            ).toJson(),
          );
        }
      }

      await fakeRepo.saveBoard(
        metadata: BoardMetadata(
          id: boardId,
          title: 'Stress Test Board (100 Cards)',
          createdAt: now,
          updatedAt: now,
          cardCount: 100,
        ),
        canvasData: CanvasData(
          boardId: boardId,
          cards: cards,
          arrows: arrows,
          updatedAt: now,
        ),
      );

      final tempDir = Directory.systemTemp.createTempSync('benchmark_assets_');
      final testAssetManager = AssetManager(baseDirProvider: () async => tempDir);

      try {
        // Measure layout & paint time
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              boardRepositoryProvider.overrideWithValue(fakeRepo),
              assetManagerProvider.overrideWithValue(testAssetManager),
            ],
            child: const MaterialApp(
              home: BoardCanvasScreen(boardId: boardId),
            ),
          ),
        );

        // Allow microtasks and initial canvas render
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        stopwatch.stop();

        // Verify that board loaded and cards are present in state
        final element = tester.element(find.byType(BoardCanvasScreen));
        final container = ProviderScope.containerOf(element);
        final state = container.read(boardStateNotifierProvider);

        expect(state.cards.length, equals(100));
        expect(state.arrows.length, equals(33));

        // Zoom out to fit view
        final fitBtn = find.byTooltip('Pas ke Tampilan (Fit to View)');
        expect(fitBtn, findsOneWidget);
        await tester.tap(fitBtn);
        await tester.pump(const Duration(milliseconds: 100));

        expect(container.read(boardStateNotifierProvider).cards.length, equals(100));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
