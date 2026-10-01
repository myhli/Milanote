import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/connector_arrow.dart';

/// Interactive anchor points rendered at the 4 cardinal edges of a selected card.
/// Allows clicking or dragging to initiate or terminate a relational connector arrow.
class CardAnchorPoints extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final void Function(CardAnchor anchor, DragStartDetails details)? onPanStart;
  final void Function(DragUpdateDetails details)? onPanUpdate;
  final void Function(DragEndDetails details)? onPanEnd;
  final ValueChanged<CardAnchor>? onAnchorTap;

  const CardAnchorPoints({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onAnchorTap,
  });

  @override
  Widget build(BuildContext context) {
    const dotSize = 14.0;
    const halfDot = dotSize / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Top Anchor
        Positioned(
          left: cardWidth / 2 - halfDot,
          top: -halfDot,
          child: _AnchorDot(
            anchor: CardAnchor.top,
            size: dotSize,
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            onTap: () => onAnchorTap?.call(CardAnchor.top),
          ),
        ),

        // Right Anchor
        Positioned(
          left: cardWidth - halfDot,
          top: cardHeight / 2 - halfDot,
          child: _AnchorDot(
            anchor: CardAnchor.right,
            size: dotSize,
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            onTap: () => onAnchorTap?.call(CardAnchor.right),
          ),
        ),

        // Bottom Anchor
        Positioned(
          left: cardWidth / 2 - halfDot,
          top: cardHeight - halfDot,
          child: _AnchorDot(
            anchor: CardAnchor.bottom,
            size: dotSize,
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            onTap: () => onAnchorTap?.call(CardAnchor.bottom),
          ),
        ),

        // Left Anchor
        Positioned(
          left: -halfDot,
          top: cardHeight / 2 - halfDot,
          child: _AnchorDot(
            anchor: CardAnchor.left,
            size: dotSize,
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            onTap: () => onAnchorTap?.call(CardAnchor.left),
          ),
        ),
      ],
    );
  }
}

class _AnchorDot extends StatefulWidget {
  final CardAnchor anchor;
  final double size;
  final void Function(CardAnchor anchor, DragStartDetails details)? onPanStart;
  final void Function(DragUpdateDetails details)? onPanUpdate;
  final void Function(DragEndDetails details)? onPanEnd;
  final VoidCallback? onTap;

  const _AnchorDot({
    required this.anchor,
    required this.size,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onTap,
  });

  @override
  State<_AnchorDot> createState() => _AnchorDotState();
}

class _AnchorDotState extends State<_AnchorDot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart: (details) => widget.onPanStart?.call(widget.anchor, details),
        onPanUpdate: widget.onPanUpdate,
        onPanEnd: widget.onPanEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _isHovered ? widget.size * 1.3 : widget.size,
          height: _isHovered ? widget.size * 1.3 : widget.size,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.accentPrimary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentPrimary,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
