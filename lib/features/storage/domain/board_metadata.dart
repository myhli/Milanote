import 'package:flutter/foundation.dart';

/// Immutable domain model representing board metadata for project management and dashboard display.
@immutable
class BoardMetadata {
  final String id;
  final String title;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int cardCount;

  const BoardMetadata({
    required this.id,
    required this.title,
    this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
    this.cardCount = 0,
  });

  BoardMetadata copyWith({
    String? id,
    String? title,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cardCount,
  }) {
    return BoardMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardCount: cardCount ?? this.cardCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'cardCount': cardCount,
    };
  }

  factory BoardMetadata.fromJson(Map<dynamic, dynamic> json) {
    return BoardMetadata(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? 'Untitled Board',
      thumbnailPath: json['thumbnailPath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          thumbnailPath == other.thumbnailPath &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          cardCount == other.cardCount;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        thumbnailPath,
        createdAt,
        updatedAt,
        cardCount,
      );

  @override
  String toString() =>
      'BoardMetadata(id: $id, title: $title, cardCount: $cardCount, updatedAt: $updatedAt)';
}
