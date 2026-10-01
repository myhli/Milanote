import 'package:flutter/foundation.dart';
import '../../../core/constants/canvas_constants.dart';
import 'base_card.dart';

/// Immutable card model for nested sub-boards (board-in-a-board) (US-009 & FR-12).
/// Displays board folder visuals, card count badge, and opens child canvas upon double-click.
@immutable
class SubBoardCard extends BaseCard {
  final String targetBoardId;
  final String title;
  final int cardCount;
  final String description;
  final String colorHex;

  const SubBoardCard({
    required super.id,
    super.type = CardType.subboard,
    required super.x,
    required super.y,
    super.width = 280.0,
    super.height = 180.0,
    super.zIndex = 0,
    required super.createdAt,
    required super.updatedAt,
    required this.targetBoardId,
    this.title = 'Sub-Board Baru',
    this.cardCount = 0,
    this.description = '',
    this.colorHex = '#6366F1',
  });

  SubBoardCard copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? targetBoardId,
    String? title,
    int? cardCount,
    String? description,
    String? colorHex,
  }) {
    return SubBoardCard(
      id: id ?? this.id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      targetBoardId: targetBoardId ?? this.targetBoardId,
      title: title ?? this.title,
      cardCount: cardCount ?? this.cardCount,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  SubBoardCard moveTo(double newX, double newY) => copyWith(
        x: newX,
        y: newY,
        updatedAt: DateTime.now(),
      );

  @override
  SubBoardCard resizeTo(double newWidth, double newHeight) => copyWith(
        width: newWidth.clamp(CanvasConstants.minCardWidth, 2000.0),
        height: newHeight.clamp(CanvasConstants.minCardHeight, 3000.0),
        updatedAt: DateTime.now(),
      );

  @override
  SubBoardCard withZIndex(int newZIndex) => copyWith(
        zIndex: newZIndex,
        updatedAt: DateTime.now(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'subboard',
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'zIndex': zIndex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'targetBoardId': targetBoardId,
        'title': title,
        'cardCount': cardCount,
        'description': description,
        'colorHex': colorHex,
      };

  factory SubBoardCard.fromJson(Map<String, dynamic> json) {
    return SubBoardCard(
      id: json['id'] as String,
      type: CardType.subboard,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 280.0,
      height: (json['height'] as num?)?.toDouble() ?? 180.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      targetBoardId: json['targetBoardId'] as String? ?? '',
      title: json['title'] as String? ?? 'Sub-Board Baru',
      cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#6366F1',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubBoardCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          zIndex == other.zIndex &&
          targetBoardId == other.targetBoardId &&
          title == other.title &&
          cardCount == other.cardCount &&
          description == other.description &&
          colorHex == other.colorHex;

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        width,
        height,
        zIndex,
        targetBoardId,
        title,
        cardCount,
        description,
        colorHex,
      );
}
