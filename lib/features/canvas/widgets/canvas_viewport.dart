import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/canvas_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../controller/canvas_controller.dart';
import 'canvas_overlay_controls.dart';
import 'dot_grid_painter.dart';

/// The core infinite canvas viewport widget.
/// Coordinates the [InteractiveViewer], [DotGridPainter], gesture handling (mouse wheel zoom,
/// spacebar pan, trackpad pinch), and canvas content layering.
class CanvasViewport extends StatefulWidget {
  final CanvasController controller;
  final Widget? content;
  final Rect? contentBounds;
  final bool isSaving;
  final String? lastSavedMessage;
  final Widget? floatingToolbar;

  const CanvasViewport({
    super.key,
    required this.controller,
    this.content,
    this.contentBounds,
    this.isSaving = false,
    this.lastSavedMessage = 'Tersimpan di lokal',
    this.floatingToolbar,
  });

  @override
  State<CanvasViewport> createState() => _CanvasViewportState();
}

class _CanvasViewportState extends State<CanvasViewport> {
  bool _isSpacePressed = false;
  bool _isDraggingPan = false;
  Offset? _lastPointerPos;

  void _handleFitToView() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? MediaQuery.of(context).size;
    final bounds = widget.contentBounds ?? Rect.fromCenter(center: Offset.zero, width: 800, height: 600);
    widget.controller.fitToView(
      contentBounds: bounds,
      viewportSize: size,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // If Control or Meta (Command on Mac) is pressed, or standard scroll zoom is desired
      final isZoomModifier = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isZoomModifier) {
        // Zoom centered at cursor position
        final zoomDelta = -event.scrollDelta.dy * 0.002;
        final targetScale = (widget.controller.scale + zoomDelta).clamp(
          CanvasConstants.minZoom,
          CanvasConstants.maxZoom,
        );
        widget.controller.setScale(targetScale, focalPoint: event.position);
      } else {
        // Pan canvas with trackpad 2-finger scroll or mouse wheel
        widget.controller.panBy(-event.scrollDelta);
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final isMiddleClick = (event.buttons & kMiddleMouseButton) != 0;
    final isSpacePan = _isSpacePressed && ((event.buttons & kPrimaryMouseButton) != 0);

    if (isMiddleClick || isSpacePan) {
      setState(() {
        _isDraggingPan = true;
        _lastPointerPos = event.position;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isDraggingPan && _lastPointerPos != null) {
      final delta = event.position - _lastPointerPos!;
      widget.controller.panBy(delta);
      _lastPointerPos = event.position;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isDraggingPan) {
      setState(() {
        _isDraggingPan = false;
        _lastPointerPos = null;
      });
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isDraggingPan) {
      setState(() {
        _isDraggingPan = false;
        _lastPointerPos = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridDotColor = isDark ? AppColors.darkGridDot : AppColors.lightGridDot;
    final canvasBg = isDark ? AppColors.darkCanvasBackground : AppColors.lightCanvasBackground;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        final isSpace = event.logicalKey == LogicalKeyboardKey.space;
        if (isSpace) {
          final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
          if (_isSpacePressed != isDown) {
            setState(() {
              _isSpacePressed = isDown;
              if (!isDown) {
                _isDraggingPan = false;
                _lastPointerPos = null;
              }
            });
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: _isDraggingPan
            ? SystemMouseCursors.grabbing
            : (_isSpacePressed ? SystemMouseCursors.grab : SystemMouseCursors.basic),
        child: Listener(
          onPointerSignal: _handlePointerSignal,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: Container(
            color: canvasBg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Dot Grid Background (O(screen) GPU batch drawing)
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: DotGridPainter(
                        transformation: widget.controller.transformationController.value,
                        dotColor: gridDotColor,
                        baseSpacing: CanvasConstants.gridSpacing,
                        baseDotRadius: CanvasConstants.dotRadius,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Layer 2: Interactive Transformable Canvas Content
                InteractiveViewer(
                  transformationController: widget.controller.transformationController,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(CanvasConstants.virtualBoundaryMargin),
                  minScale: CanvasConstants.minZoom,
                  maxScale: CanvasConstants.maxZoom,
                  panEnabled: false,
                  scaleEnabled: true,
                  child: widget.content ?? const SizedBox.shrink(),
                ),

                // Layer 3: Floating Left Toolbar Dock (if provided)
                if (widget.floatingToolbar != null)
                  Positioned(
                    left: 20,
                    top: 100,
                    child: widget.floatingToolbar!,
                  ),

                // Layer 4: Overlay Controls (Zoom percentage, Fit to View, Autosave Status)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: CanvasOverlayControls(
                    controller: widget.controller,
                    onFitToView: _handleFitToView,
                    isSaving: widget.isSaving,
                    lastSavedMessage: widget.lastSavedMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
