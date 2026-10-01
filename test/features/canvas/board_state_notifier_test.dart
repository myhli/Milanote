import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/connector_arrow.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/canvas/controller/board_state_notifier.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/board_repository.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';
import 'package:localboard/features/storage/storage_providers.dart';

class FakeBoardRepository implements BoardRepository {
  final Map<String, BoardMetadata> metadataStore = {};
  final Map<String, CanvasData> canvasStore = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<BoardMetadata>> getBoards() async => metadataStore.values.toList();

  @override
  Future<BoardMetadata?> getBoardMetadata(String boardId) async => metadataStore[boardId];

  @override
  Future<CanvasData?> getCanvasData(String boardId) async => canvasStore[boardId];

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
    );
    metadataStore[newId] = meta;
    return meta;
  }
}

void main() {
  group('BoardStateNotifier Tests (STS-01 & STS-02)', () {
    late FakeBoardRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeBoardRepository();
      container = ProviderContainer(
        overrides: [
          boardRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    NoteCard createNote(String id, double x, double y) {
      return NoteCard(
        id: id,
        x: x,
        y: y,
        width: 200,
        height: 150,
        zIndex: 1,
        title: 'Note $id',
        content: 'Content $id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('initial state and adding cards', () {
      final notifier = container.read(boardStateNotifierProvider.notifier);
      var state = container.read(boardStateNotifierProvider);

      expect(state.cards, isEmpty);
      expect(state.canUndo, isFalse);

      final card1 = createNote('card-1', 100, 100);
      notifier.addCard(card1);

      state = container.read(boardStateNotifierProvider);
      expect(state.cards.length, equals(1));
      expect(state.cards.first.id, equals('card-1'));
      expect(state.selectedCardId, equals('card-1'));
      expect(state.canUndo, isTrue);
    });

    test('undo and redo card addition', () {
      final notifier = container.read(boardStateNotifierProvider.notifier);

      notifier.addCard(createNote('card-1', 100, 100));
      expect(container.read(boardStateNotifierProvider).cards.length, equals(1));

      // Undo add
      final undone = notifier.undo();
      expect(undone, isTrue);
      expect(container.read(boardStateNotifierProvider).cards, isEmpty);
      expect(container.read(boardStateNotifierProvider).canRedo, isTrue);

      // Redo add
      final redone = notifier.redo();
      expect(redone, isTrue);
      expect(container.read(boardStateNotifierProvider).cards.length, equals(1));
      expect(container.read(boardStateNotifierProvider).cards.first.id, equals('card-1'));
    });

    test('moving card and undoing move restores original coordinates', () {
      final notifier = container.read(boardStateNotifierProvider.notifier);
      final card = createNote('card-1', 50, 60);
      notifier.addCard(card);

      notifier.moveCard('card-1', 120, 140, isFinal: true, startX: 50, startY: 60);

      var state = container.read(boardStateNotifierProvider);
      expect(state.cards.first.x, equals(120));
      expect(state.cards.first.y, equals(140));

      // Undo move
      notifier.undo();
      state = container.read(boardStateNotifierProvider);
      expect(state.cards.first.x, equals(50));
      expect(state.cards.first.y, equals(60));

      // Redo move
      notifier.redo();
      state = container.read(boardStateNotifierProvider);
      expect(state.cards.first.x, equals(120));
      expect(state.cards.first.y, equals(140));
    });

    test('deleting card cascades to connected arrows and undo restores both', () {
      final notifier = container.read(boardStateNotifierProvider.notifier);
      final card1 = createNote('c1', 0, 0);
      final card2 = createNote('c2', 200, 0);

      notifier.addCard(card1);
      notifier.addCard(card2);

      const arrow = ConnectorArrow(
        id: 'arrow-1',
        startCardId: 'c1',
        endCardId: 'c2',
      );
      notifier.addArrow(arrow);

      expect(container.read(boardStateNotifierProvider).arrows.length, equals(1));

      // Delete card 1
      notifier.deleteCard('c1');

      var state = container.read(boardStateNotifierProvider);
      expect(state.cards.length, equals(1));
      expect(state.cards.first.id, equals('c2'));
      expect(state.arrows, isEmpty); // Arrow cascaded

      // Undo delete
      notifier.undo();
      state = container.read(boardStateNotifierProvider);
      expect(state.cards.length, equals(2));
      expect(state.arrows.length, equals(1));
      expect(state.arrows.first.id, equals('arrow-1'));

      // Redo delete
      notifier.redo();
      state = container.read(boardStateNotifierProvider);
      expect(state.cards.length, equals(1));
      expect(state.arrows, isEmpty);
    });

    test('duplicating a card clones attributes with offset and increments zIndex', () {
      final notifier = container.read(boardStateNotifierProvider.notifier);
      final card = createNote('c1', 100, 100);
      notifier.addCard(card);

      notifier.duplicateCard('c1');

      final state = container.read(boardStateNotifierProvider);
      expect(state.cards.length, equals(2));
      final clone = state.cards.last;
      expect(clone.x, equals(130));
      expect(clone.y, equals(130));
      expect(clone.zIndex, greaterThan(card.zIndex));
    });

    test('persistence saves state to repository upon flushAutosave', () async {
      final notifier = container.read(boardStateNotifierProvider.notifier);
      await notifier.loadBoard('my-test-board', defaultTitle: 'Proyek Karakter');

      final note = createNote('c1', 50, 50);
      notifier.addCard(note);

      await notifier.flushAutosave();

      expect(fakeRepo.metadataStore.containsKey('my-test-board'), isTrue);
      expect(fakeRepo.canvasStore.containsKey('my-test-board'), isTrue);
      expect(fakeRepo.canvasStore['my-test-board']!.cards.length, equals(1));
    });
  });
}
