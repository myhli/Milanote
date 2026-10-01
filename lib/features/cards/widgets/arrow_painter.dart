import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bezier_math.dart';
import '../models/base_card.dart';
import '../models/connector_arrow.dart';

/// CustomPainter rendering all relational connector arrows between cards on the canvas.
/// Automatically updates when cards move, resize, or when a new connection is being dragged.
class ArrowPainter extends CustomPainter {
  final List<ConnectorArrow> arrows;
  final Map<String, BaseCard> cardMap;
  final String? selectedArrowId;
  final Offset? previewStartPoint;
  final Offset? previewEndPoint;

  ArrowPainter({
    required this.arrows,
    required this.cardMap,
    this.selectedArrowId,
    this.previewStartPoint,
    this.previewEndPoint,
  });

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF64748B);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final arrow in arrows) {
      final startCard = cardMap[arrow.startCardId];
      final endCard = cardMap[arrow.endCardId];
      if (startCard == null || endCard == null) continue;

      final startPt = BezierMath.getAnchorOffset(startCard.bounds, arrow.startAnchor);
      final endPt = BezierMath.getAnchorOffset(endCard.bounds, arrow.endAnchor);

      final isSelected = arrow.id == selectedArrowId;
      final arrowColor = isSelected ? AppColors.accentPrimary : _parseHex(arrow.colorHex);
      final strokeW = isSelected ? arrow.strokeWidth + 1.5 : arrow.strokeWidth;

      final linePaint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final headPaint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.fill;

      // Compute Path based on style
      Path path;
      switch (arrow.style) {
        case ArrowStyle.straight:
          path = BezierMath.computeStraightPath(start: startPt, end: endPt);
          break;
        case ArrowStyle.orthogonal:
          path = BezierMath.computeOrthogonalPath(
            start: startPt,
            end: endPt,
            startAnchor: arrow.startAnchor,
            endAnchor: arrow.endAnchor,
          );
          break;
        case ArrowStyle.curved:
          path = BezierMath.computeCurvedBezierPath(
            start: startPt,
            end: endPt,
            startAnchor: arrow.startAnchor,
            endAnchor: arrow.endAnchor,
          );
          break;
      }

      // Draw Main Line
      canvas.drawPath(path, linePaint);

      // Draw Arrowhead at End
      if (arrow.head == ArrowHead.end || arrow.head == ArrowHead.both) {
        final precedingPt = BezierMath.getPrecedingPoint(
          start: startPt,
          end: endPt,
          startAnchor: arrow.startAnchor,
          endAnchor: arrow.endAnchor,
          style: arrow.style,
        );
        final endHead = BezierMath.computeArrowHeadPath(
          tip: endPt,
          fromPoint: precedingPt,
          size: 10.0 + strokeW * 1.5,
        );
        canvas.drawPath(endHead, headPaint);
      }

      // Draw Arrowhead at Start
      if (arrow.head == ArrowHead.both) {
        final precedingStart = BezierMath.getPrecedingPoint(
          start: endPt,
          end: startPt,
          startAnchor: arrow.endAnchor,
          endAnchor: arrow.startAnchor,
          style: arrow.style,
        );
        final startHead = BezierMath.computeArrowHeadPath(
          tip: startPt,
          fromPoint: precedingStart,
          size: 10.0 + strokeW * 1.5,
        );
        canvas.drawPath(startHead, headPaint);
      }
    }

    // Draw In-Progress Interactive Dragging Preview Arrow
    if (previewStartPoint != null && previewEndPoint != null) {
      final previewPaint = Paint()
        ..color = AppColors.accentPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final previewPath = BezierMath.computeStraightPath(
        start: previewStartPoint!,
        end: previewEndPoint!,
      );
      canvas.drawPath(previewPath, previewPaint);

      final previewHead = BezierMath.computeArrowHeadPath(
        tip: previewEndPoint!,
        fromPoint: previewStartPoint!,
        size: 14.0,
      );
      final headFill = Paint()
        ..color = AppColors.accentPrimary
        ..style = PaintingStyle.fill;
      canvas.drawPath(previewHead, headFill);
    }
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return oldDelegate.arrows != arrows ||
        oldDelegate.cardMap != cardMap ||
        oldDelegate.selectedArrowId != selectedArrowId ||
        oldDelegate.previewStartPoint != previewStartPoint ||
        oldDelegate.previewEndPoint != previewEndPoint;
  }
}
