import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/core/constants/canvas_constants.dart';
import 'package:localboard/features/canvas/controller/canvas_controller.dart';

void main() {
  group('CanvasController', () {
    late CanvasController controller;

    setUp(() {
      controller = CanvasController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial scale is 1.0 (100%)', () {
      expect(controller.scale, closeTo(1.0, 0.001));
      expect(controller.zoomPercentageString, equals('100%'));
    });

    test('zoomIn increases scale within max limits', () {
      final initialScale = controller.scale;
      controller.zoomIn();
      expect(controller.scale, greaterThan(initialScale));

      // Attempt to zoom in beyond maxZoom
      for (int i = 0; i < 50; i++) {
        controller.zoomIn();
      }
      expect(controller.scale, lessThanOrEqualTo(CanvasConstants.maxZoom));
    });

    test('zoomOut decreases scale within min limits', () {
      final initialScale = controller.scale;
      controller.zoomOut();
      expect(controller.scale, lessThan(initialScale));

      // Attempt to zoom out beyond minZoom
      for (int i = 0; i < 50; i++) {
        controller.zoomOut();
      }
      expect(controller.scale, greaterThanOrEqualTo(CanvasConstants.minZoom));
    });

    test('resetZoom sets scale back to exactly 1.0', () {
      controller.zoomIn();
      controller.zoomIn();
      expect(controller.scale, isNot(closeTo(1.0, 0.001)));

      controller.resetZoom();
      expect(controller.scale, closeTo(1.0, 0.001));
      expect(controller.zoomPercentageString, equals('100%'));
    });

    test('screenToCanvas and canvasToScreen are reciprocal', () {
      controller.setScale(1.5, focalPoint: const Offset(200, 200));

      const originalCanvasPoint = Offset(150, 300);
      final screenPoint = controller.canvasToScreen(originalCanvasPoint);
      final recoveredCanvasPoint = controller.screenToCanvas(screenPoint);

      expect(recoveredCanvasPoint.dx, closeTo(originalCanvasPoint.dx, 0.01));
      expect(recoveredCanvasPoint.dy, closeTo(originalCanvasPoint.dy, 0.01));
    });

    test('fitToView calculates fitted scale and centers content', () {
      const content = Rect.fromLTWH(0, 0, 1000, 500);
      const viewport = Size(800, 600);

      controller.fitToView(
        contentBounds: content,
        viewportSize: viewport,
      );

      // Scale should be <= 1.0 because content width (1000) > viewport width (800)
      expect(controller.scale, lessThan(1.0));
      expect(controller.scale, greaterThanOrEqualTo(CanvasConstants.minZoom));
    });

    test('panBy translates the canvas matrix', () {
      final initialTranslation = controller.translation;
      controller.panBy(const Offset(50, -30));
      final newTranslation = controller.translation;

      expect(newTranslation.dx, closeTo(initialTranslation.dx + 50, 0.01));
      expect(newTranslation.dy, closeTo(initialTranslation.dy - 30, 0.01));
    });
  });
}
