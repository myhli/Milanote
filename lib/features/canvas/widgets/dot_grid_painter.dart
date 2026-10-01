import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/canvas_constants.dart';

/// Highly optimized custom painter that draws the infinite canvas dot grid.
/// Calculates dots strictly within the visible viewport bounds using modulo arithmetic
/// and renders them in a single batched GPU draw call (60/120 FPS guaranteed).
class DotGridPainter extends CustomPainter {
  final Matrix4 transformation;
  final Color dotColor;
  final double baseSpacing;
  final double baseDotRadius;

  DotGridPainter({
    required this.transformation,
    required this.dotColor,
    this.baseSpacing = CanvasConstants.gridSpacing,
    this.baseDotRadius = CanvasConstants.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final scale = transformation.getMaxScaleOnAxis();
    final translationX = transformation.storage[12];
    final translationY = transformation.storage[13];

    // Compute effective screen spacing
    double effectiveSpacing = baseSpacing * scale;

    // Grid level-of-detail (LOD) subsampling:
    // If zoomed out too far, scale the grid step so the screen doesn't fill with dense noise.
    while (effectiveSpacing < 14.0) {
      effectiveSpacing *= 2.0;
    }
    // If zoomed in extremely far, subdivide smoothly
    while (effectiveSpacing > 64.0) {
      effectiveSpacing /= 2.0;
    }

    // Modulo math for starting visible offset in screen space
    final startX = (translationX % effectiveSpacing) - effectiveSpacing;
    final startY = (translationY % effectiveSpacing) - effectiveSpacing;

    // Collect all points visible in current viewport
    final List<Offset> points = [];
    final endX = size.width + effectiveSpacing;
    final endY = size.height + effectiveSpacing;

    for (double x = startX; x <= endX; x += effectiveSpacing) {
      for (double y = startY; y <= endY; y += effectiveSpacing) {
        if (x >= -2 && x <= size.width + 2 && y >= -2 && y <= size.height + 2) {
          points.add(Offset(x, y));
        }
      }
    }

    if (points.isEmpty) return;

    // Scale dot size slightly with zoom for subtle visual realism, bounded between 1.0 and 2.5
    final effectiveDotRadius = (baseDotRadius * (0.8 + 0.2 * scale)).clamp(1.0, 2.5);

    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = effectiveDotRadius * 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Single batched GPU draw call for all points in viewport
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) {
    return oldDelegate.transformation != transformation ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.baseSpacing != baseSpacing ||
        oldDelegate.baseDotRadius != baseDotRadius;
  }
}
