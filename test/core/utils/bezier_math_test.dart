import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/core/utils/bezier_math.dart';
import 'package:localboard/features/cards/models/connector_arrow.dart';

void main() {
  group('BezierMath Tests (ARW-02)', () {
    const rect = Rect.fromLTWH(100, 100, 200, 150);

    test('getAnchorOffset calculates edges accurately', () {
      expect(
        BezierMath.getAnchorOffset(rect, CardAnchor.top),
        equals(const Offset(200, 100)),
      );
      expect(
        BezierMath.getAnchorOffset(rect, CardAnchor.right),
        equals(const Offset(300, 175)),
      );
      expect(
        BezierMath.getAnchorOffset(rect, CardAnchor.bottom),
        equals(const Offset(200, 250)),
      );
      expect(
        BezierMath.getAnchorOffset(rect, CardAnchor.left),
        equals(const Offset(100, 175)),
      );
    });

    test('computeCurvedBezierPath generates valid non-empty path', () {
      const start = Offset(100, 100);
      const end = Offset(400, 300);
      final path = BezierMath.computeCurvedBezierPath(
        start: start,
        end: end,
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
      );

      final bounds = path.getBounds();
      expect(bounds.left, lessThanOrEqualTo(100.0));
      expect(bounds.right, greaterThanOrEqualTo(400.0));
    });

    test('computeOrthogonalPath generates stepped path', () {
      const start = Offset(200, 100);
      const end = Offset(500, 400);
      final path = BezierMath.computeOrthogonalPath(
        start: start,
        end: end,
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
      );

      final bounds = path.getBounds();
      expect(bounds.isEmpty, isFalse);
    });

    test('computeArrowHeadPath returns closed triangular path', () {
      const tip = Offset(300, 300);
      const from = Offset(200, 300);
      final arrowPath = BezierMath.computeArrowHeadPath(tip: tip, fromPoint: from);

      final bounds = arrowPath.getBounds();
      expect(bounds.inflate(1.0).contains(tip), isTrue);
      expect(bounds.isEmpty, isFalse);
    });
  });
}
