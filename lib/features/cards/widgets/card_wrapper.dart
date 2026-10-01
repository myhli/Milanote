import 'package:flutter/material.dart';
import '../../../core/constants/canvas_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/base_card.dart';
import '../models/connector_arrow.dart';
import 'card_anchor_points.dart';

/// Callback type when user initiates or updates drawing a connector arrow from an anchor.
typedef ArrowDragCallback = void Function(
  String cardId,
  CardAnchor anchor,
  Offset canvasPosition,
);

/// Interactive wrapper providing dragging, selection borders, resize handles,
/// quick action bar, anchor points, and [RepaintBoundary] isolation for canvas cards.
class CardWrapper extends StatefulWidget {
  final BaseCard card;
  final bool isSelected;
  final double canvasScale;
  final Widget child;
  final VoidCallback? onSelect;
  final void Function(double newX, double newY)? onMove;
  final void Function(double finalX, double finalY, double startX, double startY)? onMoveEnd;
  final void Function(double newWidth, double newHeight)? onResize;
  final void Function(double finalWidth, double finalHeight, double startWidth, double startHeight)? onResizeEnd;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onBringToFront;
  final ArrowDragCallback? onArrowDragStart;
  final ValueChanged<Offset>? onArrowDragUpdate;
  final ValueChanged<Offset>? onArrowDragEnd;

  const CardWrapper({
    super.key,
    required this.card,
    required this.child,
    this.isSelected = false,
    this.canvasScale = 1.0,
    this.onSelect,
    this.onMove,
    this.onMoveEnd,
    this.onResize,
    this.onResizeEnd,
    this.onDelete,
    this.onDuplicate,
    this.onBringToFront,
    this.onArrowDragStart,
    this.onArrowDragUpdate,
    this.onArrowDragEnd,
  });

  @override
  State<CardWrapper> createState() => _CardWrapperState();
}

class _CardWrapperState extends State<CardWrapper> {
  bool _isDragging = false;
  bool _isResizing = false;

  double _dragStartX = 0.0;
  double _dragStartY = 0.0;
  double _currentX = 0.0;
  double _currentY = 0.0;

  double _resizeStartW = 0.0;
  double _resizeStartH = 0.0;
  double _currentW = 0.0;
  double _currentH = 0.0;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.onMove == null) return;
    final scale = widget.canvasScale > 0 ? widget.canvasScale : 1.0;
    final deltaX = details.delta.dx / scale;
    final deltaY = details.delta.dy / scale;
    _currentX += deltaX;
    _currentY += deltaY;
    widget.onMove!(_currentX, _currentY);
  }

  void _handleResizeUpdate(DragUpdateDetails details) {
    if (widget.onResize == null) return;
    final scale = widget.canvasScale > 0 ? widget.canvasScale : 1.0;
    final deltaX = details.delta.dx / scale;
    final deltaY = details.delta.dy / scale;

    double targetW = _currentW + deltaX;
    double targetH = _currentH + deltaY;

    // US-005: Proportional resizing for ImageCard maintaining aspect ratio
    if (widget.card.width > 0 && widget.card.height > 0 && widget.card.runtimeType.toString() == 'ImageCard') {
      final aspectRatio = widget.card.width / widget.card.height;
      if (deltaX.abs() >= deltaY.abs()) {
        targetW = targetW.clamp(CanvasConstants.minCardWidth, 4000.0);
        targetH = (targetW / aspectRatio).clamp(CanvasConstants.minCardHeight, 4000.0);
      } else {
        targetH = targetH.clamp(CanvasConstants.minCardHeight, 4000.0);
        targetW = (targetH * aspectRatio).clamp(CanvasConstants.minCardWidth, 4000.0);
      }
    } else {
      targetW = targetW.clamp(CanvasConstants.minCardWidth, 4000.0);
      targetH = targetH.clamp(CanvasConstants.minCardHeight, 4000.0);
    }

    _currentW = targetW;
    _currentH = targetH;
    widget.onResize!(targetW, targetH);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: widget.card.x,
      top: widget.card.y,
      width: widget.card.width,
      height: widget.card.height,
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Card Content with Drag Detector and Selection Border
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSelect,
              onPanStart: (_) {
                widget.onSelect?.call();
                _dragStartX = widget.card.x;
                _dragStartY = widget.card.y;
                _currentX = widget.card.x;
                _currentY = widget.card.y;
                setState(() => _isDragging = true);
              },
              onPanUpdate: _handleDragUpdate,
              onPanEnd: (_) {
                setState(() => _isDragging = false);
                widget.onMoveEnd?.call(_currentX, _currentY, _dragStartX, _dragStartY);
              },
              child: MouseRegion(
                cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
                child: Container(
                  width: widget.card.width,
                  height: widget.card.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isSelected
                          ? AppColors.accentPrimary
                          : Colors.transparent,
                      width: 2.0,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accentPrimary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: widget.child,
                ),
              ),
            ),

            // Top Drag Grip Layer (28px height across the top so dragging isn't swallowed by child TextFields)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 28,
              child: GestureDetector(
                key: const Key('note_card_drag_handle'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSelect,
                onPanStart: (_) {
                  widget.onSelect?.call();
                  _dragStartX = widget.card.x;
                  _dragStartY = widget.card.y;
                  _currentX = widget.card.x;
                  _currentY = widget.card.y;
                  setState(() => _isDragging = true);
                },
                onPanUpdate: _handleDragUpdate,
                onPanEnd: (_) {
                  setState(() => _isDragging = false);
                  widget.onMoveEnd?.call(_currentX, _currentY, _dragStartX, _dragStartY);
                },
                child: MouseRegion(
                  cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // Top Quick Action Bar when Selected
            if (widget.isSelected)
              Positioned(
                top: -38,
                left: 0,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onBringToFront != null)
                        _ActionIconBtn(
                          icon: Icons.flip_to_front_rounded,
                          tooltip: 'Bawa ke Depan',
                          onPressed: widget.onBringToFront!,
                        ),
                      if (widget.onDuplicate != null)
                        _ActionIconBtn(
                          icon: Icons.copy_rounded,
                          tooltip: 'Duplikasi Kartu',
                          onPressed: widget.onDuplicate!,
                        ),
                      if (widget.onDelete != null)
                        _ActionIconBtn(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Hapus Kartu',
                          color: AppColors.accentDanger,
                          onPressed: widget.onDelete!,
                        ),
                    ],
                  ),
                ),
              ),

            // Bottom-Right Corner Resize Handle
            if (widget.isSelected)
              Positioned(
                right: -6,
                bottom: -6,
                child: GestureDetector(
                  key: const Key('card_resize_handle'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    _resizeStartW = widget.card.width;
                    _resizeStartH = widget.card.height;
                    _currentW = widget.card.width;
                    _currentH = widget.card.height;
                    setState(() => _isResizing = true);
                  },
                  onPanUpdate: _handleResizeUpdate,
                  onPanEnd: (_) {
                    setState(() => _isResizing = false);
                    widget.onResizeEnd?.call(_currentW, _currentH, _resizeStartW, _resizeStartH);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentPrimary,
                          width: _isResizing ? 3.0 : 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Interactive Anchor Points for Connecting Arrows
            if (widget.isSelected)
              CardAnchorPoints(
                cardWidth: widget.card.width,
                cardHeight: widget.card.height,
                onPanStart: (anchor, details) {
                  final scale = widget.canvasScale > 0 ? widget.canvasScale : 1.0;
                  final localCanvas = details.globalPosition / scale;
                  widget.onArrowDragStart?.call(widget.card.id, anchor, localCanvas);
                },
                onPanUpdate: (details) {
                  final scale = widget.canvasScale > 0 ? widget.canvasScale : 1.0;
                  final localCanvas = details.globalPosition / scale;
                  widget.onArrowDragUpdate?.call(localCanvas);
                },
                onPanEnd: (details) {
                  widget.onArrowDragEnd?.call(Offset.zero);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onPressed;

  const _ActionIconBtn({
    required this.icon,
    required this.tooltip,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16, color: color),
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      onPressed: onPressed,
    );
  }
}
