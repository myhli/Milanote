import 'package:flutter/foundation.dart';
import '../../../core/constants/canvas_constants.dart';
import 'base_card.dart';

/// Immutable model for Color Swatch Cards supporting 1 to 8 swatches with HEX/RGB codes.
@immutable
class ColorCard extends BaseCard {
  final String title;
  final List<String> colorsHex;

  /// Default vibrant artist starting palette.
  static const List<String> defaultPalette = [
    '#2C3E50', // Slate Navy
    '#E74C3C', // Studio Crimson
    '#3498DB', // Sky Blue
    '#F1C40F', // Warm Sunflower
  ];

  const ColorCard({
    required super.id,
    super.type = CardType.color,
    required super.x,
    required super.y,
    super.width = 280.0,
    super.height = 140.0,
    super.zIndex = 0,
    required super.createdAt,
    required super.updatedAt,
    this.title = 'Palet Warna',
    this.colorsHex = defaultPalette,
  });

  ColorCard copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    List<String>? colorsHex,
  }) {
    return ColorCard(
      id: id ?? this.id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      colorsHex: colorsHex ?? this.colorsHex,
    );
  }

  @override
  ColorCard moveTo(double newX, double newY) => copyWith(
        x: newX,
        y: newY,
        updatedAt: DateTime.now(),
      );

  @override
  ColorCard resizeTo(double newWidth, double newHeight) => copyWith(
        width: newWidth.clamp(CanvasConstants.minCardWidth, 1200.0),
        height: newHeight.clamp(CanvasConstants.minCardHeight, 1000.0),
        updatedAt: DateTime.now(),
      );

  @override
  ColorCard withZIndex(int newZIndex) => copyWith(
        zIndex: newZIndex,
        updatedAt: DateTime.now(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'color',
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'zIndex': zIndex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'title': title,
        'colorsHex': colorsHex,
      };

  factory ColorCard.fromJson(Map<String, dynamic> json) {
    final rawColors = json['colorsHex'] as List<dynamic>? ?? defaultPalette;
    final typedColors = rawColors.map((c) => c.toString()).toList();

    return ColorCard(
      id: json['id'] as String,
      type: CardType.color,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 280.0,
      height: (json['height'] as num?)?.toDouble() ?? 140.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      title: json['title'] as String? ?? 'Palet Warna',
      colorsHex: typedColors,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          zIndex == other.zIndex &&
          title == other.title &&
          listEquals(colorsHex, other.colorsHex);

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        width,
        height,
        zIndex,
        title,
        Object.hashAll(colorsHex),
      );
}
