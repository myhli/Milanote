import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/canvas_constants.dart';

/// Controller responsible for managing the infinite canvas transformation matrix,
/// zoom operations (10% to 400%), coordinate translations (screen <-> canvas),
/// and fit-to-view calculations.
class CanvasController extends ChangeNotifier {
  final TransformationController transformationController;
  final double minZoom;
  final double maxZoom;

  CanvasController({
    TransformationController? transformationController,
    this.minZoom = CanvasConstants.minZoom,
    this.maxZoom = CanvasConstants.maxZoom,
  }) : transformationController =
            transformationController ?? TransformationController() {
    this.transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    notifyListeners();
  }

  /// Current 2D scale factor extracted from the transformation matrix.
  double get scale {
    final matrix = transformationController.value;
    final x = matrix.storage[0];
    final y = matrix.storage[1];
    return math.sqrt(x * x + y * y);
  }

  /// Current zoom formatted as a percentage string (e.g., '100%', '125%').
  String get zoomPercentageString {
    return '${(scale * 100).round()}%';
  }

  /// Current translation offset (top-left displacement in screen space).
  Offset get translation {
    final matrix = transformationController.value;
    return Offset(matrix.storage[12], matrix.storage[13]);
  }

  /// Converts a screen/viewport coordinate to canvas world coordinate space.
  Offset screenToCanvas(Offset screenOffset) {
    final matrix = transformationController.value;
    final inverted = Matrix4.tryInvert(matrix);
    if (inverted == null) return screenOffset;
    return MatrixUtils.transformPoint(inverted, screenOffset);
  }

  /// Converts a canvas world coordinate to screen/viewport coordinate space.
  Offset canvasToScreen(Offset canvasOffset) {
    final matrix = transformationController.value;
    return MatrixUtils.transformPoint(matrix, canvasOffset);
  }

  /// Zooms in by the given step, optionally keeping [focalPoint] pinned.
  void zoomIn({Offset? focalPoint, double step = CanvasConstants.zoomStep}) {
    final targetScale = (scale + step).clamp(minZoom, maxZoom);
    setScale(targetScale, focalPoint: focalPoint);
  }

  /// Zooms out by the given step, optionally keeping [focalPoint] pinned.
  void zoomOut({Offset? focalPoint, double step = CanvasConstants.zoomStep}) {
    final targetScale = (scale - step).clamp(minZoom, maxZoom);
    setScale(targetScale, focalPoint: focalPoint);
  }

  /// Resets zoom to exactly 1.0 (100%), keeping [focalPoint] pinned.
  void resetZoom({Offset? focalPoint}) {
    setScale(CanvasConstants.defaultZoom, focalPoint: focalPoint);
  }

  /// Sets the scale to [targetScale], pinning [focalPoint] (or (0,0) if null).
  void setScale(double targetScale, {Offset? focalPoint}) {
    final clampedScale = targetScale.clamp(minZoom, maxZoom);
    final currentScale = scale;
    if ((clampedScale - currentScale).abs() < 0.0001) return;

    final focal = focalPoint ?? Offset.zero;

    // Point in canvas world space under focal point before scale
    final worldFocal = screenToCanvas(focal);

    // Compute new translation so that worldFocal remains under focal
    final newTranslationX = focal.dx - (worldFocal.dx * clampedScale);
    final newTranslationY = focal.dy - (worldFocal.dy * clampedScale);

    final newMatrix = Matrix4.identity()
      ..setTranslationRaw(newTranslationX, newTranslationY, 0.0)
      ..storage[0] = clampedScale
      ..storage[5] = clampedScale;

    transformationController.value = newMatrix;
  }

  /// Moves the canvas viewport by the specified delta in screen pixels.
  void panBy(Offset delta) {
    final matrix = Matrix4.copy(transformationController.value);
    final currentTx = matrix.storage[12];
    final currentTy = matrix.storage[13];
    matrix.storage[12] = currentTx + delta.dx;
    matrix.storage[13] = currentTy + delta.dy;
    transformationController.value = matrix;
  }

  /// Calculates and applies matrix transformation to neatly enclose all elements within the viewport.
  void fitToView({
    required Rect contentBounds,
    required Size viewportSize,
    EdgeInsets padding = CanvasConstants.defaultViewportPadding,
  }) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;
    if (contentBounds.isEmpty || contentBounds.isInfinite) {
      // If content bounds are empty, center to 0,0 at 100%
      final centerTranslationX = viewportSize.width / 2;
      final centerTranslationY = viewportSize.height / 2;
      final newMatrix = Matrix4.identity()
        ..setTranslationRaw(centerTranslationX, centerTranslationY, 0.0);
      transformationController.value = newMatrix;
      return;
    }

    final availableWidth = math.max(10.0, viewportSize.width - padding.horizontal);
    final availableHeight = math.max(10.0, viewportSize.height - padding.vertical);

    final scaleX = availableWidth / contentBounds.width;
    final scaleY = availableHeight / contentBounds.height;
    final fittedScale = math.min(scaleX, scaleY).clamp(minZoom, maxZoom);

    // Center content in viewport
    final scaledContentWidth = contentBounds.width * fittedScale;
    final scaledContentHeight = contentBounds.height * fittedScale;

    final translationX = padding.left + (availableWidth - scaledContentWidth) / 2 - (contentBounds.left * fittedScale);
    final translationY = padding.top + (availableHeight - scaledContentHeight) / 2 - (contentBounds.top * fittedScale);

    final newMatrix = Matrix4.identity()
      ..setTranslationRaw(translationX, translationY, 0.0)
      ..storage[0] = fittedScale
      ..storage[5] = fittedScale;

    transformationController.value = newMatrix;
  }

  @override
  void dispose() {
    transformationController.removeListener(_onTransformationChanged);
    transformationController.dispose();
    super.dispose();
  }
}
