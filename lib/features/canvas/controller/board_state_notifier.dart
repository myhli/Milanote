import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cards/models/base_card.dart';
import '../../cards/models/color_card.dart';
import '../../cards/models/connector_arrow.dart';
import '../../cards/models/image_card.dart';
import '../../cards/models/link_card.dart';
import '../../cards/models/note_card.dart';
import '../../cards/models/subboard_card.dart';
import '../../history/controller/history_controller.dart';
import '../../history/models/canvas_action.dart';
import '../../storage/domain/autosave_service.dart';
import '../../storage/domain/board_metadata.dart';
import '../../storage/domain/board_repository.dart';
import '../../storage/domain/canvas_data.dart';
import '../../storage/storage_providers.dart';
import 'board_state.dart';

/// Riverpod Notifier orchestrating the infinite canvas state, card mutations,
/// command-based Undo/Redo stack, and debounced 400ms local-first autosave.
class BoardStateNotifier extends Notifier<BoardState> {
  late final BoardRepository _repository;
  late final HistoryController _historyController;
  AutosaveEngine? _autosaveEngine;

  @override
  BoardState build() {
    _repository = ref.watch(boardRepositoryProvider);
    _historyController = HistoryController(maxHistory: 50);

    _autosaveEngine = AutosaveEngine(
      debounceDuration: const Duration(milliseconds: 400),
      onSave: _persistCurrentState,
      onStatusChanged: (status) {
        state = state.copyWith(autosaveStatus: status);
      },
    );

    ref.onDispose(() {
      _autosaveEngine?.dispose();
    });

    return BoardState.initial('default_board');
  }

  /// Initial load or switch to a specific board.
  Future<void> loadBoard(String boardId, {String? defaultTitle}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final meta = await _repository.getBoardMetadata(boardId);
      final canvas = await _repository.getCanvasData(boardId);
      _historyController.clear();

      if (meta != null && canvas != null) {
        final loadedCards = canvas.cards.map((m) => BaseCard.fromJson(m)).toList();
        final loadedArrows = canvas.arrows.map((m) => ConnectorArrow.fromJson(m)).toList();

        int maxZ = 1;
        for (final c in loadedCards) {
          if (c.zIndex > maxZ) maxZ = c.zIndex;
        }

        state = BoardState(
          boardId: meta.id,
          title: meta.title,
          cards: List.unmodifiable(loadedCards),
          arrows: List.unmodifiable(loadedArrows),
          highestZIndex: maxZ,
          autosaveStatus: AutosaveStatus.saved,
          canUndo: false,
          canRedo: false,
          isLoading: false,
        );
      } else {
        // Create initial empty board in state and save it
        final title = defaultTitle ?? 'Papan Baru';
        state = BoardState.initial(boardId, title: title);
        await _persistCurrentState();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat papan: $e',
        autosaveStatus: AutosaveStatus.error,
      );
    }
  }

  /// Load from existing pre-configured cards and arrows (e.g. from an artistic starter template).
  Future<void> loadFromTemplate({
    required String boardId,
    required String title,
    required List<BaseCard> cards,
    required List<ConnectorArrow> arrows,
  }) async {
    _historyController.clear();
    int maxZ = 1;
    for (final c in cards) {
      if (c.zIndex > maxZ) maxZ = c.zIndex;
    }

    state = BoardState(
      boardId: boardId,
      title: title,
      cards: List.unmodifiable(cards),
      arrows: List.unmodifiable(arrows),
      highestZIndex: maxZ,
      autosaveStatus: AutosaveStatus.saving,
      canUndo: false,
      canRedo: false,
      isLoading: false,
    );

    await _persistCurrentState();
  }

  /// Adds a new card to the canvas.
  void addCard(BaseCard card, {bool recordHistory = true}) {
    final nextZ = card.zIndex > state.highestZIndex ? card.zIndex : state.highestZIndex + 1;
    final positionedCard = card.withZIndex(nextZ);
    final updatedList = List<BaseCard>.from(state.cards)..add(positionedCard);

    if (recordHistory) {
      _historyController.record(AddCardAction(positionedCard));
    }

    state = state.copyWith(
      cards: List.unmodifiable(updatedList),
      highestZIndex: nextZ,
      selectedCardId: positionedCard.id,
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Moves a card to new coordinates.
  void moveCard(
    String id,
    double x,
    double y, {
    bool isFinal = false,
    double? startX,
    double? startY,
  }) {
    final index = state.cards.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final oldCard = state.cards[index];
    final updatedCard = oldCard.moveTo(x, y);
    final updatedList = List<BaseCard>.from(state.cards)..[index] = updatedCard;

    if (isFinal && startX != null && startY != null && (startX != x || startY != y)) {
      _historyController.record(MoveCardAction(
        cardId: id,
        oldX: startX,
        oldY: startY,
        newX: x,
        newY: y,
      ));
    }

    state = state.copyWith(
      cards: List.unmodifiable(updatedList),
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Resizes a card.
  void resizeCard(
    String id,
    double width,
    double height, {
    bool isFinal = false,
    double? startWidth,
    double? startHeight,
  }) {
    final index = state.cards.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final oldCard = state.cards[index];
    final updatedCard = oldCard.resizeTo(width, height);
    final updatedList = List<BaseCard>.from(state.cards)..[index] = updatedCard;

    if (isFinal &&
        startWidth != null &&
        startHeight != null &&
        (startWidth != width || startHeight != height)) {
      _historyController.record(ResizeCardAction(
        cardId: id,
        oldWidth: startWidth,
        oldHeight: startHeight,
        newWidth: width,
        newHeight: height,
      ));
    }

    state = state.copyWith(
      cards: List.unmodifiable(updatedList),
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Updates card contents or internal state (e.g., text, checklist toggle, pastel color).
  void updateCard(BaseCard updated, {bool recordHistory = true}) {
    final index = state.cards.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;

    final oldCard = state.cards[index];
    if (recordHistory) {
      _historyController.record(UpdateCardAction(oldCard: oldCard, newCard: updated));
    }

    final updatedList = List<BaseCard>.from(state.cards)..[index] = updated;

    state = state.copyWith(
      cards: List.unmodifiable(updatedList),
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Deletes a card and cascades removal to all attached connector arrows.
  void deleteCard(String id, {bool recordHistory = true}) {
    final cardIndex = state.cards.indexWhere((c) => c.id == id);
    if (cardIndex == -1) return;

    final targetCard = state.cards[cardIndex];
    final attachedArrows = state.arrows
        .where((a) => a.startCardId == id || a.endCardId == id)
        .toList();

    final remainingCards = List<BaseCard>.from(state.cards)..removeAt(cardIndex);
    final remainingArrows = state.arrows
        .where((a) => a.startCardId != id && a.endCardId != id)
        .toList();

    if (recordHistory) {
      _historyController.record(DeleteCardAction(
        card: targetCard,
        attachedArrows: attachedArrows,
      ));
    }

    state = state.copyWith(
      cards: List.unmodifiable(remainingCards),
      arrows: List.unmodifiable(remainingArrows),
      clearSelectedCard: state.selectedCardId == id,
      clearSelectedArrow: attachedArrows.any((a) => a.id == state.selectedArrowId),
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Duplicates a card with a 30px offset and new unique ID.
  void duplicateCard(String id, {bool recordHistory = true}) {
    final index = state.cards.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final original = state.cards[index];
    final newId = 'card_${DateTime.now().microsecondsSinceEpoch}';
    final nextZ = state.highestZIndex + 1;

    BaseCard clone;
    if (original is NoteCard) {
      clone = original.copyWith(
        id: newId,
        x: original.x + 30,
        y: original.y + 30,
        zIndex: nextZ,
      );
    } else if (original is ImageCard) {
      clone = original.copyWith(
        id: newId,
        x: original.x + 30,
        y: original.y + 30,
        zIndex: nextZ,
      );
    } else if (original is ColorCard) {
      clone = original.copyWith(
        id: newId,
        x: original.x + 30,
        y: original.y + 30,
        zIndex: nextZ,
      );
    } else if (original is LinkCard) {
      clone = original.copyWith(
        id: newId,
        x: original.x + 30,
        y: original.y + 30,
        zIndex: nextZ,
      );
    } else if (original is SubBoardCard) {
      clone = original.copyWith(
        id: newId,
        x: original.x + 30,
        y: original.y + 30,
        zIndex: nextZ,
      );
    } else {
      clone = original
          .moveTo(original.x + 30, original.y + 30)
          .withZIndex(nextZ);
    }

    final updatedList = List<BaseCard>.from(state.cards)..add(clone);

    if (recordHistory) {
      _historyController.record(AddCardAction(clone));
    }

    state = state.copyWith(
      cards: List.unmodifiable(updatedList),
      highestZIndex: nextZ,
      selectedCardId: newId,
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Elevates card z-index to bring it in front of all other cards.
  void bringToFront(String id, {bool recordHistory = true}) {
    final index = state.cards.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final oldCard = state.cards[index];
    final nextZ = state.highestZIndex + 1;
    final updatedCard = oldCard.withZIndex(nextZ);
    final updatedList = List<BaseCard>.from(state.cards)..[index] = updatedCard;

    if (recordHistory) {
      _historyController.record(BringToFrontAction(
        cardId: id,
        oldZIndex: oldCard.zIndex,
        newZIndex: nextZ,
      ));
    }

    state = state.copyWith(
      cards: List.unmodifiable(updatedList),
      highestZIndex: nextZ,
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Adds a new connector arrow.
  void addArrow(ConnectorArrow arrow, {bool recordHistory = true}) {
    final updatedList = List<ConnectorArrow>.from(state.arrows)..add(arrow);

    if (recordHistory) {
      _historyController.record(AddArrowAction(arrow));
    }

    state = state.copyWith(
      arrows: List.unmodifiable(updatedList),
      selectedArrowId: arrow.id,
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Deletes a connector arrow.
  void deleteArrow(String id, {bool recordHistory = true}) {
    final index = state.arrows.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final targetArrow = state.arrows[index];
    final updatedList = List<ConnectorArrow>.from(state.arrows)..removeAt(index);

    if (recordHistory) {
      _historyController.record(DeleteArrowAction(targetArrow));
    }

    state = state.copyWith(
      arrows: List.unmodifiable(updatedList),
      clearSelectedArrow: state.selectedArrowId == id,
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Updates a connector arrow's style, head, color, or stroke width (US-008 & ARW-01..04).
  void updateArrow(ConnectorArrow updated, {bool recordHistory = true}) {
    final index = state.arrows.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;

    final oldArrow = state.arrows[index];
    if (recordHistory) {
      _historyController.record(UpdateArrowAction(oldArrow: oldArrow, newArrow: updated));
    }

    final updatedList = List<ConnectorArrow>.from(state.arrows)..[index] = updated;

    state = state.copyWith(
      arrows: List.unmodifiable(updatedList),
      selectedArrowId: updated.id,
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Selects or deselects a card.
  void selectCard(String? id) {
    if (state.selectedCardId == id && (id == null || state.selectedArrowId == null)) return;
    state = state.copyWith(
      selectedCardId: id,
      clearSelectedCard: id == null,
      clearSelectedArrow: id != null,
    );
  }

  /// Selects or deselects an arrow.
  void selectArrow(String? id) {
    if (state.selectedArrowId == id && (id == null || state.selectedCardId == null)) return;
    state = state.copyWith(
      selectedArrowId: id,
      clearSelectedArrow: id == null,
      clearSelectedCard: id != null,
    );
  }

  /// Sets arrow drawing mode.
  void setArrowMode(bool enabled) {
    if (state.isArrowMode == enabled) return;
    state = state.copyWith(isArrowMode: enabled);
  }

  /// Updates board title and triggers autosave.
  void updateTitle(String newTitle) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty || trimmed == state.title) return;
    state = state.copyWith(title: trimmed);
    _autosaveEngine?.notifyMutation();
  }

  /// Reverts the last atomic canvas action.
  bool undo() {
    final action = _historyController.undo();
    if (action == null) return false;

    _applyAction(action, isUndo: true);
    return true;
  }

  /// Re-applies the last undone atomic canvas action.
  bool redo() {
    final action = _historyController.redo();
    if (action == null) return false;

    _applyAction(action, isUndo: false);
    return true;
  }

  void _applyAction(CanvasAction action, {required bool isUndo}) {
    if (action is AddCardAction) {
      if (isUndo) {
        // Undo Add: remove card
        final updated = state.cards.where((c) => c.id != action.card.id).toList();
        state = state.copyWith(
          cards: List.unmodifiable(updated),
          clearSelectedCard: state.selectedCardId == action.card.id,
        );
      } else {
        // Redo Add: re-insert card
        final updated = List<BaseCard>.from(state.cards)..add(action.card);
        state = state.copyWith(
          cards: List.unmodifiable(updated),
          selectedCardId: action.card.id,
        );
      }
    } else if (action is DeleteCardAction) {
      if (isUndo) {
        // Undo Delete: restore card and any attached arrows
        final updatedCards = List<BaseCard>.from(state.cards)..add(action.card);
        final updatedArrows = List<ConnectorArrow>.from(state.arrows)..addAll(action.attachedArrows);
        state = state.copyWith(
          cards: List.unmodifiable(updatedCards),
          arrows: List.unmodifiable(updatedArrows),
          selectedCardId: action.card.id,
        );
      } else {
        // Redo Delete: remove card and attached arrows
        final updatedCards = state.cards.where((c) => c.id != action.card.id).toList();
        final arrowIds = action.attachedArrows.map((a) => a.id).toSet();
        final updatedArrows = state.arrows.where((a) => !arrowIds.contains(a.id)).toList();
        state = state.copyWith(
          cards: List.unmodifiable(updatedCards),
          arrows: List.unmodifiable(updatedArrows),
          clearSelectedCard: state.selectedCardId == action.card.id,
        );
      }
    } else if (action is MoveCardAction) {
      final targetX = isUndo ? action.oldX : action.newX;
      final targetY = isUndo ? action.oldY : action.newY;
      final index = state.cards.indexWhere((c) => c.id == action.cardId);
      if (index != -1) {
        final updatedList = List<BaseCard>.from(state.cards)
          ..[index] = state.cards[index].moveTo(targetX, targetY);
        state = state.copyWith(cards: List.unmodifiable(updatedList));
      }
    } else if (action is ResizeCardAction) {
      final targetW = isUndo ? action.oldWidth : action.newWidth;
      final targetH = isUndo ? action.oldHeight : action.newHeight;
      final index = state.cards.indexWhere((c) => c.id == action.cardId);
      if (index != -1) {
        final updatedList = List<BaseCard>.from(state.cards)
          ..[index] = state.cards[index].resizeTo(targetW, targetH);
        state = state.copyWith(cards: List.unmodifiable(updatedList));
      }
    } else if (action is UpdateCardAction) {
      final target = isUndo ? action.oldCard : action.newCard;
      final index = state.cards.indexWhere((c) => c.id == target.id);
      if (index != -1) {
        final updatedList = List<BaseCard>.from(state.cards)..[index] = target;
        state = state.copyWith(cards: List.unmodifiable(updatedList));
      }
    } else if (action is BringToFrontAction) {
      final targetZ = isUndo ? action.oldZIndex : action.newZIndex;
      final index = state.cards.indexWhere((c) => c.id == action.cardId);
      if (index != -1) {
        final updatedList = List<BaseCard>.from(state.cards)
          ..[index] = state.cards[index].withZIndex(targetZ);
        state = state.copyWith(cards: List.unmodifiable(updatedList));
      }
    } else if (action is AddArrowAction) {
      if (isUndo) {
        final updated = state.arrows.where((a) => a.id != action.arrow.id).toList();
        state = state.copyWith(
          arrows: List.unmodifiable(updated),
          clearSelectedArrow: state.selectedArrowId == action.arrow.id,
        );
      } else {
        final updated = List<ConnectorArrow>.from(state.arrows)..add(action.arrow);
        state = state.copyWith(
          arrows: List.unmodifiable(updated),
          selectedArrowId: action.arrow.id,
        );
      }
    } else if (action is DeleteArrowAction) {
      if (isUndo) {
        final updated = List<ConnectorArrow>.from(state.arrows)..add(action.arrow);
        state = state.copyWith(
          arrows: List.unmodifiable(updated),
          selectedArrowId: action.arrow.id,
        );
      } else {
        final updated = state.arrows.where((a) => a.id != action.arrow.id).toList();
        state = state.copyWith(
          arrows: List.unmodifiable(updated),
          clearSelectedArrow: state.selectedArrowId == action.arrow.id,
        );
      }
    } else if (action is UpdateArrowAction) {
      final target = isUndo ? action.oldArrow : action.newArrow;
      final index = state.arrows.indexWhere((a) => a.id == target.id);
      if (index != -1) {
        final updatedList = List<ConnectorArrow>.from(state.arrows)..[index] = target;
        state = state.copyWith(
          arrows: List.unmodifiable(updatedList),
          selectedArrowId: target.id,
        );
      }
    } else if (action is BatchCanvasAction) {
      final actions = isUndo ? action.actions.reversed.toList() : action.actions;
      for (final a in actions) {
        _applyAction(a, isUndo: isUndo);
      }
    }

    state = state.copyWith(
      canUndo: _historyController.canUndo,
      canRedo: _historyController.canRedo,
    );

    _autosaveEngine?.notifyMutation();
  }

  /// Forces immediate disk flush.
  Future<void> flushAutosave() async {
    await _autosaveEngine?.flush();
  }

  /// Internal persistence handler writing to Hive database.
  Future<void> _persistCurrentState() async {
    final now = DateTime.now();
    final meta = BoardMetadata(
      id: state.boardId,
      title: state.title,
      createdAt: now,
      updatedAt: now,
      cardCount: state.cards.length,
    );

    final canvas = CanvasData(
      boardId: state.boardId,
      cards: state.cards.map((c) => c.toJson()).toList(),
      arrows: state.arrows.map((a) => a.toJson()).toList(),
      updatedAt: now,
    );

    await _repository.saveBoard(metadata: meta, canvasData: canvas);
    state = state.copyWith(
      lastSaved: DateTime.now(),
      autosaveStatus: AutosaveStatus.saved,
    );
  }
}

/// Global provider for the active board state.
final boardStateNotifierProvider =
    NotifierProvider<BoardStateNotifier, BoardState>(BoardStateNotifier.new);
