import 'package:flutter/foundation.dart';
import '../../../core/constants/canvas_constants.dart';
import 'base_card.dart';

/// Immutable card model for web bookmarks with Open Graph preview,
/// offline cached cover thumbnail, and external browser link opening (US-006 & FR-9).
@immutable
class LinkCard extends BaseCard {
  final String url;
  final String title;
  final String description;
  final String siteName;
  final String coverAssetUuid;
  final String coverImageUrl;
  final String colorHex;

  const LinkCard({
    required super.id,
    super.type = CardType.link,
    required super.x,
    required super.y,
    super.width = 300.0,
    super.height = 260.0,
    super.zIndex = 0,
    required super.createdAt,
    required super.updatedAt,
    required this.url,
    this.title = '',
    this.description = '',
    this.siteName = '',
    this.coverAssetUuid = '',
    this.coverImageUrl = '',
    this.colorHex = '#FFFFFF',
  });

  LinkCard copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? url,
    String? title,
    String? description,
    String? siteName,
    String? coverAssetUuid,
    String? coverImageUrl,
    String? colorHex,
  }) {
    return LinkCard(
      id: id ?? this.id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      siteName: siteName ?? this.siteName,
      coverAssetUuid: coverAssetUuid ?? this.coverAssetUuid,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  LinkCard moveTo(double newX, double newY) => copyWith(
        x: newX,
        y: newY,
        updatedAt: DateTime.now(),
      );

  @override
  LinkCard resizeTo(double newWidth, double newHeight) => copyWith(
        width: newWidth.clamp(CanvasConstants.minCardWidth, 2000.0),
        height: newHeight.clamp(CanvasConstants.minCardHeight, 3000.0),
        updatedAt: DateTime.now(),
      );

  @override
  LinkCard withZIndex(int newZIndex) => copyWith(
        zIndex: newZIndex,
        updatedAt: DateTime.now(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'link',
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'zIndex': zIndex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'url': url,
        'title': title,
        'description': description,
        'siteName': siteName,
        'coverAssetUuid': coverAssetUuid,
        'coverImageUrl': coverImageUrl,
        'colorHex': colorHex,
      };

  factory LinkCard.fromJson(Map<String, dynamic> json) {
    return LinkCard(
      id: json['id'] as String,
      type: CardType.link,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 300.0,
      height: (json['height'] as num?)?.toDouble() ?? 260.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      siteName: json['siteName'] as String? ?? '',
      coverAssetUuid: json['coverAssetUuid'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#FFFFFF',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          zIndex == other.zIndex &&
          url == other.url &&
          title == other.title &&
          description == other.description &&
          siteName == other.siteName &&
          coverAssetUuid == other.coverAssetUuid &&
          coverImageUrl == other.coverImageUrl &&
          colorHex == other.colorHex;

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        width,
        height,
        zIndex,
        url,
        title,
        description,
        siteName,
        coverAssetUuid,
        coverImageUrl,
        colorHex,
      );
}
