import 'package:flutter/foundation.dart';

/// Immutable domain model containing the full visual layout of a board canvas:
/// card elements, relational connectors/arrows, and last viewport transform.
@immutable
class CanvasData {
  final String boardId;
  final int version;
  final List<Map<String, dynamic>> cards;
  final List<Map<String, dynamic>> arrows;
  final double viewportOffsetX;
  final double viewportOffsetY;
  final double viewportScale;
  final DateTime updatedAt;

  const CanvasData({
    required this.boardId,
    this.version = 1,
    this.cards = const [],
    this.arrows = const [],
    this.viewportOffsetX = 0.0,
    this.viewportOffsetY = 0.0,
    this.viewportScale = 1.0,
    required this.updatedAt,
  });

  CanvasData copyWith({
    String? boardId,
    int? version,
    List<Map<String, dynamic>>? cards,
    List<Map<String, dynamic>>? arrows,
    double? viewportOffsetX,
    double? viewportOffsetY,
    double? viewportScale,
    DateTime? updatedAt,
  }) {
    return CanvasData(
      boardId: boardId ?? this.boardId,
      version: version ?? this.version,
      cards: cards ?? this.cards,
      arrows: arrows ?? this.arrows,
      viewportOffsetX: viewportOffsetX ?? this.viewportOffsetX,
      viewportOffsetY: viewportOffsetY ?? this.viewportOffsetY,
      viewportScale: viewportScale ?? this.viewportScale,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boardId': boardId,
      'version': version,
      'cards': cards,
      'arrows': arrows,
      'viewportOffsetX': viewportOffsetX,
      'viewportOffsetY': viewportOffsetY,
      'viewportScale': viewportScale,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CanvasData.fromJson(Map<dynamic, dynamic> json) {
    final rawCards = json['cards'] as List<dynamic>? ?? [];
    final typedCards = rawCards.map((c) => Map<String, dynamic>.from(c as Map)).toList();

    final rawArrows = json['arrows'] as List<dynamic>? ?? [];
    final typedArrows = rawArrows.map((a) => Map<String, dynamic>.from(a as Map)).toList();

    return CanvasData(
      boardId: json['boardId'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      cards: typedCards,
      arrows: typedArrows,
      viewportOffsetX: (json['viewportOffsetX'] as num?)?.toDouble() ?? 0.0,
      viewportOffsetY: (json['viewportOffsetY'] as num?)?.toDouble() ?? 0.0,
      viewportScale: (json['viewportScale'] as num?)?.toDouble() ?? 1.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasData &&
          runtimeType == other.runtimeType &&
          boardId == other.boardId &&
          version == other.version &&
          listEquals(cards, other.cards) &&
          listEquals(arrows, other.arrows) &&
          viewportOffsetX == other.viewportOffsetX &&
          viewportOffsetY == other.viewportOffsetY &&
          viewportScale == other.viewportScale &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        boardId,
        version,
        Object.hashAll(cards),
        Object.hashAll(arrows),
        viewportOffsetX,
        viewportOffsetY,
        viewportScale,
        updatedAt,
      );

  @override
  String toString() =>
      'CanvasData(boardId: $boardId, cards: ${cards.length}, arrows: ${arrows.length}, scale: $viewportScale)';
}
