import 'dart:ui';
import '../../features/cards/models/base_card.dart';

/// Utility calculating the tight bounding box encompassing all canvas elements with proportional padding.
class BoundingBoxCalculator {
  /// Calculates the bounding box for a given list of cards, expanding with [padding].
  /// Guaranteed to return at least [minWidth] x [minHeight].
  static Rect calculate({
    required List<BaseCard> cards,
    double padding = 40.0,
    double minWidth = 600.0,
    double minHeight = 400.0,
  }) {
    if (cards.isEmpty) {
      return Rect.fromLTWH(0, 0, minWidth, minHeight);
    }

    double minX = cards.first.x;
    double minY = cards.first.y;
    double maxX = cards.first.x + cards.first.width;
    double maxY = cards.first.y + cards.first.height;

    for (int i = 1; i < cards.length; i++) {
      final c = cards[i];
      if (c.x < minX) minX = c.x;
      if (c.y < minY) minY = c.y;
      if (c.x + c.width > maxX) maxX = c.x + c.width;
      if (c.y + c.height > maxY) maxY = c.y + c.height;
    }

    // Apply padding
    double left = minX - padding;
    double top = minY - padding;
    double right = maxX + padding;
    double bottom = maxY + padding;

    double width = right - left;
    double height = bottom - top;

    // Enforce minimum dimensions if canvas content is very small
    if (width < minWidth) {
      final diff = (minWidth - width) / 2;
      left -= diff;
      right += diff;
      width = minWidth;
    }

    if (height < minHeight) {
      final diff = (minHeight - height) / 2;
      top -= diff;
      bottom += diff;
      height = minHeight;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }
}
