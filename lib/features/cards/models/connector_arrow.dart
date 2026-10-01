import 'package:flutter/foundation.dart';

/// Connection anchor point along one of the 4 edges of a card.
enum CardAnchor {
  top,
  right,
  bottom,
  left,
}

/// Visual style for connector lines.
enum ArrowStyle {
  straight,
  curved,
  orthogonal,
}

/// Arrowhead options for line terminals.
enum ArrowHead {
  none,
  end,
  both,
}

/// Immutable domain model representing a relational connector/arrow between two cards.
@immutable
class ConnectorArrow {
  final String id;
  final String startCardId;
  final String endCardId;
  final CardAnchor startAnchor;
  final CardAnchor endAnchor;
  final ArrowStyle style;
  final ArrowHead head;
  final String colorHex;
  final double strokeWidth;
  final String? label;

  const ConnectorArrow({
    required this.id,
    required this.startCardId,
    required this.endCardId,
    this.startAnchor = CardAnchor.right,
    this.endAnchor = CardAnchor.left,
    this.style = ArrowStyle.curved,
    this.head = ArrowHead.end,
    this.colorHex = '#64748B', // Studio slate
    this.strokeWidth = 2.0,
    this.label,
  });

  ConnectorArrow copyWith({
    String? id,
    String? startCardId,
    String? endCardId,
    CardAnchor? startAnchor,
    CardAnchor? endAnchor,
    ArrowStyle? style,
    ArrowHead? head,
    String? colorHex,
    double? strokeWidth,
    String? label,
  }) {
    return ConnectorArrow(
      id: id ?? this.id,
      startCardId: startCardId ?? this.startCardId,
      endCardId: endCardId ?? this.endCardId,
      startAnchor: startAnchor ?? this.startAnchor,
      endAnchor: endAnchor ?? this.endAnchor,
      style: style ?? this.style,
      head: head ?? this.head,
      colorHex: colorHex ?? this.colorHex,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startCardId': startCardId,
        'endCardId': endCardId,
        'startAnchor': startAnchor.name,
        'endAnchor': endAnchor.name,
        'style': style.name,
        'head': head.name,
        'colorHex': colorHex,
        'strokeWidth': strokeWidth,
        'label': label,
      };

  factory ConnectorArrow.fromJson(Map<String, dynamic> json) {
    return ConnectorArrow(
      id: json['id'] as String,
      startCardId: json['startCardId'] as String,
      endCardId: json['endCardId'] as String,
      startAnchor: CardAnchor.values.byName(
        json['startAnchor'] as String? ?? CardAnchor.right.name,
      ),
      endAnchor: CardAnchor.values.byName(
        json['endAnchor'] as String? ?? CardAnchor.left.name,
      ),
      style: ArrowStyle.values.byName(
        json['style'] as String? ?? ArrowStyle.curved.name,
      ),
      head: ArrowHead.values.byName(
        json['head'] as String? ?? ArrowHead.end.name,
      ),
      colorHex: json['colorHex'] as String? ?? '#64748B',
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectorArrow &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startCardId == other.startCardId &&
          endCardId == other.endCardId &&
          startAnchor == other.startAnchor &&
          endAnchor == other.endAnchor &&
          style == other.style &&
          head == other.head &&
          colorHex == other.colorHex &&
          strokeWidth == other.strokeWidth &&
          label == other.label;

  @override
  int get hashCode => Object.hash(
        id,
        startCardId,
        endCardId,
        startAnchor,
        endAnchor,
        style,
        head,
        colorHex,
        strokeWidth,
        label,
      );
}
