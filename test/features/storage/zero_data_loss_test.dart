import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:localboard/features/canvas/controller/board_state_notifier.dart';
import 'package:localboard/features/cards/models/color_card.dart';
import 'package:localboard/features/cards/models/connector_arrow.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/models/subboard_card.dart';
import 'package:localboard/features/storage/data/asset_manager.dart';
import 'package:localboard/features/storage/data/hive_board_repository.dart';
import 'package:localboard/features/storage/domain/autosave_service.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';
import 'package:localboard/features/storage/storage_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Zero Data Loss Autosave & Persistence Recovery Tests (US-010, NFR-2)', () {
    late Directory tempDir;
    late AssetManager assetManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('localboard_zdl_test_');
      Hive.init(tempDir.path);
      assetManager = AssetManager(
        baseDirProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Rapid consecutive mutations are 100% recovered on cold restart after flushAutosave', () async {
      const boardId = 'zdl_cold_restart_board';
      final repo1 = HiveBoardRepository(assetManager: assetManager);
      await repo1.init();

      // Setup initial board
      final now = DateTime.now();
      await repo1.saveBoard(
        metadata: BoardMetadata(
          id: boardId,
          title: 'Initial Artistic Project',
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

      final container = ProviderContainer(
        overrides: [
          boardRepositoryProvider.overrideWithValue(repo1),
          assetManagerProvider.overrideWithValue(assetManager),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(boardStateNotifierProvider.notifier);
      await notifier.loadBoard(boardId);

      // Perform 30 rapid mutations without yielding 400ms debounce
      for (int i = 0; i < 10; i++) {
        notifier.addCard(
          NoteCard(
            id: 'note_$i',
            x: i * 50.0,
            y: i * 40.0,
            width: 240,
            height: 180,
            title: 'Idea #$i',
            content: 'Detailed description for creative draft $i',
            checklists: [
              ChecklistItem(id: 'c_${i}_1', text: 'Task 1 for note $i', isDone: i % 2 == 0),
              ChecklistItem(id: 'c_${i}_2', text: 'Task 2 for note $i', isDone: false),
            ],
            createdAt: now,
            updatedAt: now,
          ),
          recordHistory: false,
        );
      }

      for (int i = 0; i < 5; i++) {
        notifier.addCard(
          ColorCard(
            id: 'color_$i',
            x: 600.0 + i * 20.0,
            y: 100.0 + i * 60.0,
            title: 'Palette $i',
            colorsHex: ['#FF5733', '#33FF57', '#3357FF', '#F3FF33'],
            createdAt: now,
            updatedAt: now,
          ),
          recordHistory: false,
        );
      }

      for (int i = 0; i < 5; i++) {
        notifier.addCard(
          SubBoardCard(
            id: 'subboard_$i',
            x: 900.0,
            y: i * 200.0,
            title: 'Sub-chapter $i',
            targetBoardId: 'child_board_$i',
            cardCount: i * 3,
            createdAt: now,
            updatedAt: now,
          ),
          recordHistory: false,
        );
      }

      for (int i = 0; i < 9; i++) {
        notifier.addArrow(
          ConnectorArrow(
            id: 'arrow_$i',
            startCardId: 'note_$i',
            endCardId: 'note_${i + 1}',
            startAnchor: CardAnchor.right,
            endAnchor: CardAnchor.left,
            style: ArrowStyle.curved,
            head: ArrowHead.end,
          ),
          recordHistory: false,
        );
      }

      // Mutate one note card's position and checklist
      notifier.moveCard('note_3', 999.0, 888.0, isFinal: true);
      notifier.updateCard(
        NoteCard(
          id: 'note_3',
          x: 999.0,
          y: 888.0,
          width: 240,
          height: 180,
          title: 'Modified Idea #3',
          content: 'Updated content string verify integrity',
          checklists: const [
            ChecklistItem(id: 'c_3_1', text: 'Done Task', isDone: true),
            ChecklistItem(id: 'c_3_2', text: 'Done Task 2', isDone: true),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Mutate board title
      notifier.updateTitle('Artistic Concept Evolution V2');

      // Abrupt flush before process kill
      await notifier.flushAutosave();

      // SIMULATE COLD RESTART: Close Hive and tear down all in-memory structures
      await Hive.close();

      // Reopen repository from the exact same disk location with a clean instance
      Hive.init(tempDir.path);
      final repo2 = HiveBoardRepository(assetManager: assetManager);
      await repo2.init();

      final restoredMeta = await repo2.getBoardMetadata(boardId);
      final restoredCanvas = await repo2.getCanvasData(boardId);

      // Verify metadata integrity
      expect(restoredMeta, isNotNull);
      expect(restoredMeta!.title, equals('Artistic Concept Evolution V2'));
      expect(restoredMeta.cardCount, equals(20)); // 10 notes + 5 colors + 5 subboards

      // Verify canvas cards integrity
      expect(restoredCanvas, isNotNull);
      expect(restoredCanvas!.cards.length, equals(20));
      expect(restoredCanvas.arrows.length, equals(9));

      // Verify specific mutated note card data
      final note3Map = restoredCanvas.cards.firstWhere((c) => c['id'] == 'note_3');
      expect(note3Map['x'], equals(999.0));
      expect(note3Map['y'], equals(888.0));
      expect(note3Map['title'], equals('Modified Idea #3'));
      expect(note3Map['content'], equals('Updated content string verify integrity'));
      expect((note3Map['checklists'] as List).length, equals(2));
      expect((note3Map['checklists'] as List)[0]['isDone'], isTrue);
      expect((note3Map['checklists'] as List)[1]['isDone'], isTrue);

      // Verify arrows intact
      final arrow0 = restoredCanvas.arrows.firstWhere((a) => a['id'] == 'arrow_0');
      expect(arrow0['startCardId'], equals('note_0'));
      expect(arrow0['endCardId'], equals('note_1'));
    });

    test('AutosaveEngine prevents trailing mutation drop during in-flight save', () async {
      int saveCount = 0;
      final savedSnapshots = <String>[];
      String currentData = 'initial';

      final engine = AutosaveEngine(
        debounceDuration: const Duration(milliseconds: 50),
        onSave: () async {
          saveCount++;
          // Simulate slight disk I/O delay
          await Future.delayed(const Duration(milliseconds: 40));
          savedSnapshots.add(currentData);
        },
      );

      // Initial state
      expect(engine.status, equals(AutosaveStatus.idle));
      expect(engine.hasPendingSave, isFalse);

      // First mutation
      currentData = 'mutation_1';
      engine.notifyMutation();
      expect(engine.status, equals(AutosaveStatus.saving));
      expect(engine.hasPendingSave, isTrue);

      // Wait 60ms to let debounce trigger the first save
      await Future.delayed(const Duration(milliseconds: 60));

      // While save is in-flight, a second rapid mutation occurs
      currentData = 'mutation_2_trailing';
      engine.notifyMutation();

      // Flush to ensure all trailing work finishes before checking
      await engine.flush();

      // Ensure both mutations were captured and final saved state matches trailing mutation exactly
      expect(saveCount, equals(2));
      expect(savedSnapshots.last, equals('mutation_2_trailing'));
      expect(engine.hasPendingSave, isFalse);
      expect(engine.status, equals(AutosaveStatus.saved));

      engine.dispose();
    });

    test('Cold restart with multiple boards recovers all canvases and metadata independently', () async {
      final repo1 = HiveBoardRepository(assetManager: assetManager);
      await repo1.init();

      final now = DateTime.now();

      // Create 3 independent boards with distinct content
      for (int b = 1; b <= 3; b++) {
        final bId = 'board_parallel_$b';
        await repo1.saveBoard(
          metadata: BoardMetadata(
            id: bId,
            title: 'Project Canvas #$b',
            createdAt: now,
            updatedAt: now,
            cardCount: b * 2,
          ),
          canvasData: CanvasData(
            boardId: bId,
            cards: List.generate(
              b * 2,
              (idx) => NoteCard(
                id: 'b${b}_card_$idx',
                x: idx * 100.0,
                y: idx * 80.0,
                title: 'Board $b Card $idx',
                createdAt: now,
                updatedAt: now,
              ).toJson(),
            ),
            arrows: const [],
            updatedAt: now,
          ),
        );
      }

      // Hard crash simulation
      await Hive.close();

      // New session from disk
      Hive.init(tempDir.path);
      final repo2 = HiveBoardRepository(assetManager: assetManager);
      await repo2.init();

      final allBoards = await repo2.getBoards();
      expect(allBoards.length, equals(3));

      for (int b = 1; b <= 3; b++) {
        final bId = 'board_parallel_$b';
        final meta = await repo2.getBoardMetadata(bId);
        final canvas = await repo2.getCanvasData(bId);

        expect(meta, isNotNull);
        expect(meta!.title, equals('Project Canvas #$b'));
        expect(meta.cardCount, equals(b * 2));

        expect(canvas, isNotNull);
        expect(canvas!.cards.length, equals(b * 2));
        expect(canvas.cards.first['title'], equals('Board $b Card 0'));
      }
    });
  });
}
