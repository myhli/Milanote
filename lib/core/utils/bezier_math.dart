import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../features/cards/models/connector_arrow.dart';

/// Helper methods for computing connector paths, Bezier control points,
/// orthogonal elbow routes, and arrowheads.
abstract class BezierMath {
  /// Computes the exact anchor point offset in canvas coordinates given a card bounding rect.
  static Offset getAnchorOffset(Rect rect, CardAnchor anchor) {
    switch (anchor) {
      case CardAnchor.top:
        return Offset(rect.left + rect.width / 2, rect.top);
      case CardAnchor.right:
        return Offset(rect.right, rect.top + rect.height / 2);
      case CardAnchor.bottom:
        return Offset(rect.left + rect.width / 2, rect.bottom);
      case CardAnchor.left:
        return Offset(rect.left, rect.top + rect.height / 2);
    }
  }

  /// Outward normal direction vector for the given anchor edge.
  static Offset getAnchorDirection(CardAnchor anchor) {
    switch (anchor) {
      case CardAnchor.top:
        return const Offset(0, -1);
      case CardAnchor.right:
        return const Offset(1, 0);
      case CardAnchor.bottom:
        return const Offset(0, 1);
      case CardAnchor.left:
        return const Offset(-1, 0);
    }
  }

  /// Constructs a smooth cubic Bezier path between two anchor points.
  static Path computeCurvedBezierPath({
    required Offset start,
    required Offset end,
    required CardAnchor startAnchor,
    required CardAnchor endAnchor,
  }) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final distance = (end - start).distance;
    final curvature = math.max(40.0, distance * 0.4);

    final startDir = getAnchorDirection(startAnchor);
    final endDir = getAnchorDirection(endAnchor);

    final cp1 = start + (startDir * curvature);
    final cp2 = end + (endDir * curvature);

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }

  /// Constructs a stepped orthogonal (elbow / right-angle) path between two anchor points.
  static Path computeOrthogonalPath({
    required Offset start,
    required Offset end,
    required CardAnchor startAnchor,
    required CardAnchor endAnchor,
    double clearance = 24.0,
  }) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final startDir = getAnchorDirection(startAnchor);
    final endDir = getAnchorDirection(endAnchor);

    final p1 = start + (startDir * clearance);
    final p4 = end + (endDir * clearance);

    // Depending on start/end anchor orientation, route horizontally or vertically first
    final isHorizontalStart = startAnchor == CardAnchor.left || startAnchor == CardAnchor.right;
    final isHorizontalEnd = endAnchor == CardAnchor.left || endAnchor == CardAnchor.right;

    path.lineTo(p1.dx, p1.dy);

    if (isHorizontalStart && isHorizontalEnd) {
      final midX = (p1.dx + p4.dx) / 2;
      path.lineTo(midX, p1.dy);
      path.lineTo(midX, p4.dy);
    } else if (!isHorizontalStart && !isHorizontalEnd) {
      final midY = (p1.dy + p4.dy) / 2;
      path.lineTo(p1.dx, midY);
      path.lineTo(p4.dx, midY);
    } else if (isHorizontalStart && !isHorizontalEnd) {
      path.lineTo(p4.dx, p1.dy);
    } else {
      path.lineTo(p1.dx, p4.dy);
    }

    path.lineTo(p4.dx, p4.dy);
    path.lineTo(end.dx, end.dy);
    return path;
  }

  /// Constructs a direct straight-line path between two points.
  static Path computeStraightPath({
    required Offset start,
    required Offset end,
  }) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);
    return path;
  }

  /// Computes a filled triangular arrowhead at [tip], directed from [fromPoint].
  static Path computeArrowHeadPath({
    required Offset tip,
    required Offset fromPoint,
    double size = 12.0,
    double angle = 0.45, // approx 26 degrees
  }) {
    final path = Path();
    final directionAngle = math.atan2(tip.dy - fromPoint.dy, tip.dx - fromPoint.dx);

    final leftAngle = directionAngle + math.pi - angle;
    final rightAngle = directionAngle + math.pi + angle;

    final leftPoint = Offset(
      tip.dx + size * math.cos(leftAngle),
      tip.dy + size * math.sin(leftAngle),
    );

    final rightPoint = Offset(
      tip.dx + size * math.cos(rightAngle),
      tip.dy + size * math.sin(rightAngle),
    );

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(leftPoint.dx, leftPoint.dy);
    path.lineTo(rightPoint.dx, rightPoint.dy);
    path.close();

    return path;
  }

  /// Returns the tangency direction point slightly preceding [end] along the given path style.
  static Offset getPrecedingPoint({
    required Offset start,
    required Offset end,
    required CardAnchor startAnchor,
    required CardAnchor endAnchor,
    required ArrowStyle style,
  }) {
    switch (style) {
      case ArrowStyle.straight:
        return start;
      case ArrowStyle.orthogonal:
        final endDir = getAnchorDirection(endAnchor);
        return end + (endDir * 16.0);
      case ArrowStyle.curved:
        final distance = (end - start).distance;
        final curvature = math.max(40.0, distance * 0.4);
        final endDir = getAnchorDirection(endAnchor);
        return end + (endDir * curvature * 0.25);
    }
  }

  /// Checks whether a given canvas point is within [hitRadius] of the connector arrow path.
  static bool isPointNearArrow({
    required Offset point,
    required Offset start,
    required Offset end,
    required CardAnchor startAnchor,
    required CardAnchor endAnchor,
    required ArrowStyle style,
    double hitRadius = 16.0,
  }) {
    final left = math.min(start.dx, end.dx) - hitRadius - 40;
    final right = math.max(start.dx, end.dx) + hitRadius + 40;
    final top = math.min(start.dy, end.dy) - hitRadius - 40;
    final bottom = math.max(start.dy, end.dy) + hitRadius + 40;
    if (!Rect.fromLTRB(left, top, right, bottom).contains(point)) {
      return false;
    }

    Path path;
    switch (style) {
      case ArrowStyle.straight:
        path = computeStraightPath(start: start, end: end);
        break;
      case ArrowStyle.orthogonal:
        path = computeOrthogonalPath(
          start: start,
          end: end,
          startAnchor: startAnchor,
          endAnchor: endAnchor,
        );
        break;
      case ArrowStyle.curved:
        path = computeCurvedBezierPath(
          start: start,
          end: end,
          startAnchor: startAnchor,
          endAnchor: endAnchor,
        );
        break;
    }

    for (final metric in path.computeMetrics()) {
      final totalLen = metric.length;
      if (totalLen == 0) continue;
      const step = 10.0;
      for (double d = 0; d <= totalLen; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null && (tangent.position - point).distance <= hitRadius) {
          return true;
        }
      }
    }
    return false;
  }

  /// Calculates the midpoint on the arrow path for positioning the interactive toolbar.
  static Offset getArrowMidpoint({
    required Offset start,
    required Offset end,
    required CardAnchor startAnchor,
    required CardAnchor endAnchor,
    required ArrowStyle style,
  }) {
    Path path;
    switch (style) {
      case ArrowStyle.straight:
        path = computeStraightPath(start: start, end: end);
        break;
      case ArrowStyle.orthogonal:
        path = computeOrthogonalPath(
          start: start,
          end: end,
          startAnchor: startAnchor,
          endAnchor: endAnchor,
        );
        break;
      case ArrowStyle.curved:
        path = computeCurvedBezierPath(
          start: start,
          end: end,
          startAnchor: startAnchor,
          endAnchor: endAnchor,
        );
        break;
    }

    for (final metric in path.computeMetrics()) {
      if (metric.length > 0) {
        final tangent = metric.getTangentForOffset(metric.length * 0.5);
        if (tangent != null) return tangent.position;
      }
    }
    return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  }
}
