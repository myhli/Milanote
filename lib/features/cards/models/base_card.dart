import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'color_card.dart';
import 'image_card.dart';
import 'link_card.dart';
import 'note_card.dart';
import 'subboard_card.dart';

/// Supported card types across the LocalBoard infinite canvas.
enum CardType {
  note,
  image,
  color,
  link,
  subboard,
}

/// Abstract immutable base class for all visual cards placed on the canvas.
@immutable
abstract class BaseCard {
  final String id;
  final CardType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final int zIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseCard({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.zIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Bounding rectangle in canvas world coordinates.
  Rect get bounds => Rect.fromLTWH(x, y, width, height);

  /// Center point in canvas world coordinates.
  Offset get center => Offset(x + width / 2, y + height / 2);

  /// Serializes card to JSON map.
  Map<String, dynamic> toJson();

  /// Deserializes a card instance based on the 'type' attribute.
  factory BaseCard.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String? ?? 'note';
    switch (typeString) {
      case 'image':
        return ImageCard.fromJson(json);
      case 'color':
        return ColorCard.fromJson(json);
      case 'link':
        return LinkCard.fromJson(json);
      case 'subboard':
        return SubBoardCard.fromJson(json);
      case 'note':
      default:
        return NoteCard.fromJson(json);
    }
  }

  /// Clones with updated position.
  BaseCard moveTo(double newX, double newY);

  /// Clones with updated dimensions.
  BaseCard resizeTo(double newWidth, double newHeight);

  /// Clones with updated z-index.
  BaseCard withZIndex(int newZIndex);
}
