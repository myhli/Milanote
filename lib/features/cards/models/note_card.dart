import 'package:flutter/foundation.dart';
import '../../../core/constants/canvas_constants.dart';
import 'base_card.dart';

/// Single item within a note checklist.
@immutable
class ChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isDone,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          isDone == other.isDone;

  @override
  int get hashCode => Object.hash(id, text, isDone);
}

/// Immutable model for Note Cards supporting rich body text, checklists, and pastel themes.
@immutable
class NoteCard extends BaseCard {
  final String title;
  final String content;
  final String colorHex;
  final List<ChecklistItem> checklists;
  final bool isChecklistMode;

  /// Default pastel theme colors (yellow, green, blue, peach, gray, white).
  static const List<String> pastelColors = [
    '#FFFFFF', // Studio Clean White
    '#FEF9C3', // Soft Pastel Yellow
    '#DCFCE7', // Soft Pastel Green
    '#E0F2FE', // Soft Pastel Blue
    '#FFEDD5', // Soft Pastel Peach
    '#F3F4F6', // Soft Pastel Slate / Neutral Gray
  ];

  const NoteCard({
    required super.id,
    super.type = CardType.note,
    required super.x,
    required super.y,
    super.width = CanvasConstants.defaultCardWidth,
    super.height = CanvasConstants.defaultCardHeight,
    super.zIndex = 0,
    required super.createdAt,
    required super.updatedAt,
    this.title = '',
    this.content = '',
    this.colorHex = '#FEF9C3',
    this.checklists = const [],
    this.isChecklistMode = false,
  });

  NoteCard copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? content,
    String? colorHex,
    List<ChecklistItem>? checklists,
    bool? isChecklistMode,
  }) {
    return NoteCard(
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
      content: content ?? this.content,
      colorHex: colorHex ?? this.colorHex,
      checklists: checklists ?? this.checklists,
      isChecklistMode: isChecklistMode ?? this.isChecklistMode,
    );
  }

  @override
  NoteCard moveTo(double newX, double newY) => copyWith(
        x: newX,
        y: newY,
        updatedAt: DateTime.now(),
      );

  @override
  NoteCard resizeTo(double newWidth, double newHeight) => copyWith(
        width: newWidth.clamp(CanvasConstants.minCardWidth, 2000.0),
        height: newHeight.clamp(CanvasConstants.minCardHeight, 3000.0),
        updatedAt: DateTime.now(),
      );

  @override
  NoteCard withZIndex(int newZIndex) => copyWith(
        zIndex: newZIndex,
        updatedAt: DateTime.now(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'note',
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'zIndex': zIndex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'title': title,
        'content': content,
        'colorHex': colorHex,
        'checklists': checklists.map((e) => e.toJson()).toList(),
        'isChecklistMode': isChecklistMode,
      };

  factory NoteCard.fromJson(Map<String, dynamic> json) {
    final rawChecklists = json['checklists'] as List<dynamic>? ?? [];
    final typedChecklists = rawChecklists
        .map((c) => ChecklistItem.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    return NoteCard(
      id: json['id'] as String,
      type: CardType.note,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? CanvasConstants.defaultCardWidth,
      height: (json['height'] as num?)?.toDouble() ?? CanvasConstants.defaultCardHeight,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#FEF9C3',
      checklists: typedChecklists,
      isChecklistMode: json['isChecklistMode'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          zIndex == other.zIndex &&
          title == other.title &&
          content == other.content &&
          colorHex == other.colorHex &&
          isChecklistMode == other.isChecklistMode &&
          listEquals(checklists, other.checklists);

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        width,
        height,
        zIndex,
        title,
        content,
        colorHex,
        isChecklistMode,
        Object.hashAll(checklists),
      );
}
