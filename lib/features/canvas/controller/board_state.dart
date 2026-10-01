import 'package:flutter/foundation.dart';
import '../../cards/models/base_card.dart';
import '../../cards/models/connector_arrow.dart';
import '../../storage/domain/autosave_service.dart';

/// Immutable state holding the complete canvas board model, selection, and sync status.
@immutable
class BoardState {
  final String boardId;
  final String title;
  final List<BaseCard> cards;
  final List<ConnectorArrow> arrows;
  final String? selectedCardId;
  final String? selectedArrowId;
  final bool isArrowMode;
  final int highestZIndex;
  final AutosaveStatus autosaveStatus;
  final bool canUndo;
  final bool canRedo;
  final DateTime? lastSaved;
  final bool isLoading;
  final String? errorMessage;

  const BoardState({
    required this.boardId,
    required this.title,
    this.cards = const [],
    this.arrows = const [],
    this.selectedCardId,
    this.selectedArrowId,
    this.isArrowMode = false,
    this.highestZIndex = 1,
    this.autosaveStatus = AutosaveStatus.idle,
    this.canUndo = false,
    this.canRedo = false,
    this.lastSaved,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Factory for an initial empty board.
  factory BoardState.initial(String boardId, {String title = 'Papan Tanpa Judul'}) {
    return BoardState(
      boardId: boardId,
      title: title,
      cards: const [],
      arrows: const [],
      isLoading: false,
    );
  }

  int get cardCount => cards.length;
  bool get isEmpty => cards.isEmpty;

  BaseCard? get selectedCard {
    if (selectedCardId == null) return null;
    try {
      return cards.firstWhere((c) => c.id == selectedCardId);
    } catch (_) {
      return null;
    }
  }

  ConnectorArrow? get selectedArrow {
    if (selectedArrowId == null) return null;
    try {
      return arrows.firstWhere((a) => a.id == selectedArrowId);
    } catch (_) {
      return null;
    }
  }

  BoardState copyWith({
    String? boardId,
    String? title,
    List<BaseCard>? cards,
    List<ConnectorArrow>? arrows,
    String? selectedCardId,
    bool clearSelectedCard = false,
    String? selectedArrowId,
    bool clearSelectedArrow = false,
    bool? isArrowMode,
    int? highestZIndex,
    AutosaveStatus? autosaveStatus,
    bool? canUndo,
    bool? canRedo,
    DateTime? lastSaved,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BoardState(
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      cards: cards ?? this.cards,
      arrows: arrows ?? this.arrows,
      selectedCardId: clearSelectedCard ? null : (selectedCardId ?? this.selectedCardId),
      selectedArrowId: clearSelectedArrow ? null : (selectedArrowId ?? this.selectedArrowId),
      isArrowMode: isArrowMode ?? this.isArrowMode,
      highestZIndex: highestZIndex ?? this.highestZIndex,
      autosaveStatus: autosaveStatus ?? this.autosaveStatus,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      lastSaved: lastSaved ?? this.lastSaved,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardState &&
        other.boardId == boardId &&
        other.title == title &&
        listEquals(other.cards, cards) &&
        listEquals(other.arrows, arrows) &&
        other.selectedCardId == selectedCardId &&
        other.selectedArrowId == selectedArrowId &&
        other.isArrowMode == isArrowMode &&
        other.highestZIndex == highestZIndex &&
        other.autosaveStatus == autosaveStatus &&
        other.canUndo == canUndo &&
        other.canRedo == canRedo &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode => Object.hash(
        boardId,
        title,
        cards.length,
        arrows.length,
        selectedCardId,
        selectedArrowId,
        isArrowMode,
        highestZIndex,
        autosaveStatus,
        canUndo,
        canRedo,
        isLoading,
      );
}
