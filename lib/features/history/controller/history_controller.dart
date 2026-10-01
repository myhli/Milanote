import 'dart:collection';
import '../models/canvas_action.dart';

/// Controller managing the Undo and Redo command history with a bounded circular buffer (default 50 actions).
/// Keeps memory footprint well below 2MB by storing only atomic diffs rather than full canvas snapshots.
class HistoryController {
  final int maxHistory;
  final ListQueue<CanvasAction> _undoStack = ListQueue<CanvasAction>();
  final ListQueue<CanvasAction> _redoStack = ListQueue<CanvasAction>();

  HistoryController({this.maxHistory = 50});

  /// True if there are actions available to undo.
  bool get canUndo => _undoStack.isNotEmpty;

  /// True if there are actions available to redo.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Current number of undoable actions in the stack.
  int get undoCount => _undoStack.length;

  /// Current number of redoable actions in the stack.
  int get redoCount => _redoStack.length;

  /// Records a new action to the undo stack.
  /// Clears the redo stack and ensures stack size does not exceed [maxHistory].
  void record(CanvasAction action) {
    _redoStack.clear();
    if (_undoStack.length >= maxHistory) {
      _undoStack.removeFirst();
    }
    _undoStack.addLast(action);
  }

  /// Pops the latest action from the undo stack and moves it to the redo stack.
  /// Returns the action that should be reversed, or null if nothing to undo.
  CanvasAction? undo() {
    if (!canUndo) return null;
    final action = _undoStack.removeLast();
    _redoStack.addLast(action);
    return action;
  }

  /// Pops the latest action from the redo stack and moves it to the undo stack.
  /// Returns the action that should be re-applied, or null if nothing to redo.
  CanvasAction? redo() {
    if (!canRedo) return null;
    final action = _redoStack.removeLast();
    _undoStack.addLast(action);
    return action;
  }

  /// Clears all undo and redo history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
