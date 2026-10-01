import 'package:flutter/foundation.dart';
import '../../../core/constants/canvas_constants.dart';
import 'base_card.dart';

/// Immutable model for Image Cards supporting proportional resizing, local sandboxed assets, and captions.
@immutable
class ImageCard extends BaseCard {
  final String assetUuid;
  final String caption;
  final double aspectRatio;
  final double? originalWidth;
  final double? originalHeight;

  const ImageCard({
    required super.id,
    super.type = CardType.image,
    required super.x,
    required super.y,
    super.width = 300.0,
    super.height = 240.0,
    super.zIndex = 0,
    required super.createdAt,
    required super.updatedAt,
    required this.assetUuid,
    this.caption = '',
    this.aspectRatio = 1.25,
    this.originalWidth,
    this.originalHeight,
  });

  ImageCard copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assetUuid,
    String? caption,
    double? aspectRatio,
    double? originalWidth,
    double? originalHeight,
  }) {
    return ImageCard(
      id: id ?? this.id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assetUuid: assetUuid ?? this.assetUuid,
      caption: caption ?? this.caption,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
    );
  }

  @override
  ImageCard moveTo(double newX, double newY) => copyWith(
        x: newX,
        y: newY,
        updatedAt: DateTime.now(),
      );

  @override
  ImageCard resizeTo(double newWidth, double newHeight) {
    final clampedW = newWidth.clamp(CanvasConstants.minCardWidth, 3000.0);
    // Keep proportional height based on aspectRatio if available
    final proportionalH = aspectRatio > 0 ? clampedW / aspectRatio : newHeight;
    final clampedH = proportionalH.clamp(CanvasConstants.minCardHeight, 3000.0);

    return copyWith(
      width: clampedW,
      height: clampedH,
      updatedAt: DateTime.now(),
    );
  }

  @override
  ImageCard withZIndex(int newZIndex) => copyWith(
        zIndex: newZIndex,
        updatedAt: DateTime.now(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'image',
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'zIndex': zIndex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'assetUuid': assetUuid,
        'caption': caption,
        'aspectRatio': aspectRatio,
        'originalWidth': originalWidth,
        'originalHeight': originalHeight,
      };

  factory ImageCard.fromJson(Map<String, dynamic> json) {
    return ImageCard(
      id: json['id'] as String,
      type: CardType.image,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 300.0,
      height: (json['height'] as num?)?.toDouble() ?? 240.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      assetUuid: json['assetUuid'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? 1.25,
      originalWidth: (json['originalWidth'] as num?)?.toDouble(),
      originalHeight: (json['originalHeight'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          zIndex == other.zIndex &&
          assetUuid == other.assetUuid &&
          caption == other.caption &&
          aspectRatio == other.aspectRatio;

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        width,
        height,
        zIndex,
        assetUuid,
        caption,
        aspectRatio,
      );
}
