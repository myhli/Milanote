import 'package:flutter/material.dart';

/// Constants and constraints for the LocalBoard canvas engine.
abstract class CanvasConstants {
  // Zoom & Viewport constraints (US-003: 10% to 400%)
  static const double minZoom = 0.10;
  static const double maxZoom = 4.00;
  static const double defaultZoom = 1.00;
  static const double zoomStep = 0.15;

  // Infinite canvas virtual boundary margin
  static const double virtualBoundaryMargin = 50000.0;

  // Dot Grid settings
  static const double gridSpacing = 28.0;
  static const double dotRadius = 1.25;

  // Card Constraints
  static const double minCardWidth = 140.0;
  static const double minCardHeight = 90.0;
  static const double defaultCardWidth = 260.0;
  static const double defaultCardHeight = 180.0;

  // Animation durations
  static const Duration zoomAnimationDuration = Duration(milliseconds: 200);
  static const Duration autosaveDebounceDuration = Duration(milliseconds: 400);

  // Z-Index Layers
  static const double zIndexGrid = 0.0;
  static const double zIndexArrows = 1.0;
  static const double zIndexCards = 10.0;
  static const double zIndexOverlay = 100.0;

  // Default padding
  static const EdgeInsets defaultViewportPadding = EdgeInsets.all(40.0);
}
