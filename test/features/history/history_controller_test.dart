import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/history/controller/history_controller.dart';
import 'package:localboard/features/history/models/canvas_action.dart';

void main() {
  group('HistoryController Tests (STS-02)', () {
    late HistoryController controller;
    late NoteCard dummyCard;

    setUp(() {
      controller = HistoryController(maxHistory: 3);
      dummyCard = NoteCard(
        id: 'card-1',
        x: 100,
        y: 100,
        width: 200,
        height: 150,
        zIndex: 1,
        title: 'Title',
        content: 'Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('initial state has empty undo and redo stacks', () {
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      expect(controller.undoCount, equals(0));
      expect(controller.redoCount, equals(0));
      expect(controller.undo(), isNull);
      expect(controller.redo(), isNull);
    });

    test('recording an action enables undo and clears redo', () {
      final action = AddCardAction(dummyCard);
      controller.record(action);

      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);
      expect(controller.undoCount, equals(1));

      // Perform undo
      final undone = controller.undo();
      expect(undone, equals(action));
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);
      expect(controller.redoCount, equals(1));

      // Perform redo
      final redone = controller.redo();
      expect(redone, equals(action));
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);
    });

    test('recording a new action after undo clears redo stack', () {
      controller.record(const MoveCardAction(
        cardId: 'c1',
        oldX: 0,
        oldY: 0,
        newX: 10,
        newY: 10,
      ));
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.record(const MoveCardAction(
        cardId: 'c1',
        oldX: 0,
        oldY: 0,
        newX: 50,
        newY: 50,
      ));
      expect(controller.canRedo, isFalse);
    });

    test('enforces maxHistory limit and discards oldest action', () {
      controller.record(const MoveCardAction(
        cardId: 'c1',
        oldX: 0,
        oldY: 0,
        newX: 1,
        newY: 1,
      ));
      controller.record(const MoveCardAction(
        cardId: 'c1',
        oldX: 1,
        oldY: 1,
        newX: 2,
        newY: 2,
      ));
      controller.record(const MoveCardAction(
        cardId: 'c1',
        oldX: 2,
        oldY: 2,
        newX: 3,
        newY: 3,
      ));
      controller.record(const MoveCardAction(
        cardId: 'c1',
        oldX: 3,
        oldY: 3,
        newX: 4,
        newY: 4,
      ));

      expect(controller.undoCount, equals(3));

      final a3 = controller.undo() as MoveCardAction;
      expect(a3.newX, equals(4));
      final a2 = controller.undo() as MoveCardAction;
      expect(a2.newX, equals(3));
      final a1 = controller.undo() as MoveCardAction;
      expect(a1.newX, equals(2));
      expect(controller.undo(), isNull);
    });

    test('clear resets both undo and redo stacks', () {
      controller.record(AddCardAction(dummyCard));
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.clear();
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });
  });
}
