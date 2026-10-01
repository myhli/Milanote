import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bezier_math.dart';
import '../../../../core/utils/bounding_box_calculator.dart';
import '../../../cards/models/base_card.dart';
import '../../../cards/models/color_card.dart';
import '../../../cards/models/connector_arrow.dart';
import '../../../cards/models/image_card.dart';
import '../../../cards/models/link_card.dart';
import '../../../cards/models/note_card.dart';
import '../../../cards/models/subboard_card.dart';
import '../../../storage/storage_providers.dart';

/// Lightweight, hardware-accelerated miniature canvas preview renderer (US-001 & GAL-01).
/// Displays a scaled visual snapshot of actual board cards, pastel colors, and connector lines.
class BoardMiniThumbnail extends ConsumerStatefulWidget {
  final String boardId;
  final bool isDark;

  const BoardMiniThumbnail({
    super.key,
    required this.boardId,
    required this.isDark,
  });

  @override
  ConsumerState<BoardMiniThumbnail> createState() => _BoardMiniThumbnailState();
}

class _BoardMiniThumbnailState extends ConsumerState<BoardMiniThumbnail> {
  List<BaseCard>? _cards;
  List<ConnectorArrow>? _arrows;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(covariant BoardMiniThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boardId != widget.boardId) {
      _loadPreview();
    }
  }

  Future<void> _loadPreview() async {
    try {
      final repo = ref.read(boardRepositoryProvider);
      final canvasData = await repo.getCanvasData(widget.boardId);

      if (!mounted) return;

      if (canvasData != null) {
        final parsedCards = canvasData.cards
            .map((c) => BaseCard.fromJson(c))
            .toList();
        final parsedArrows = canvasData.arrows
            .map((a) => ConnectorArrow.fromJson(a))
            .toList();

        setState(() {
          _cards = parsedCards;
          _arrows = parsedArrows;
          _isLoading = false;
        });
      } else {
        setState(() {
          _cards = const [];
          _arrows = const [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cards = const [];
          _arrows = const [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: widget.isDark ? const Color(0xFF131720) : const Color(0xFFF1F5F9),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
      );
    }

    final cards = _cards ?? const [];
    final arrows = _arrows ?? const [];

    if (cards.isEmpty) {
      return Container(
        color: widget.isDark ? const Color(0xFF131720) : const Color(0xFFF1F5F9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_rounded,
                size: 32,
                color: widget.isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.7)
                    : AppColors.lightBorder.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 4),
              Text(
                'Kanvas Kosong',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
                      : AppColors.lightTextSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bounds = BoundingBoxCalculator.calculate(cards: cards, padding: 24.0);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
        child: Container(
          color: widget.isDark ? const Color(0xFF131720) : const Color(0xFFF8FAFC),
          child: CustomPaint(
            painter: _MiniCanvasPreviewPainter(
              cards: cards,
              arrows: arrows,
              contentBounds: bounds,
              isDark: widget.isDark,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// CustomPainter that renders a scaled miniature representation of cards and connectors.
class _MiniCanvasPreviewPainter extends CustomPainter {
  final List<BaseCard> cards;
  final List<ConnectorArrow> arrows;
  final Rect contentBounds;
  final bool isDark;

  const _MiniCanvasPreviewPainter({
    required this.cards,
    required this.arrows,
    required this.contentBounds,
    required this.isDark,
  });

  Color _parseHex(String hex, {Color fallback = const Color(0xFFFEF9C3)}) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cards.isEmpty || size.width <= 0 || size.height <= 0) return;

    final scaleX = size.width / contentBounds.width;
    final scaleY = size.height / contentBounds.height;
    final scale = math.min(scaleX, scaleY).clamp(0.01, 1.0);

    final scaledContentW = contentBounds.width * scale;
    final scaledContentH = contentBounds.height * scale;

    final dx = (size.width - scaledContentW) / 2 - contentBounds.left * scale;
    final dy = (size.height - scaledContentH) / 2 - contentBounds.top * scale;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final cardMap = {for (final c in cards) c.id: c};

    // 1. Paint miniature connector arrows
    final arrowPaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, 1.5 / scale)
      ..strokeCap = StrokeCap.round;

    for (final arrow in arrows) {
      final startCard = cardMap[arrow.startCardId];
      final endCard = cardMap[arrow.endCardId];
      if (startCard == null || endCard == null) continue;

      final startPt = BezierMath.getAnchorOffset(startCard.bounds, arrow.startAnchor);
      final endPt = BezierMath.getAnchorOffset(endCard.bounds, arrow.endAnchor);

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
      canvas.drawPath(path, arrowPaint);
    }

    // 2. Paint miniature cards sorted by zIndex
    final sorted = List<BaseCard>.from(cards)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (final card in sorted) {
      final cardRect = RRect.fromRectAndRadius(card.bounds, const Radius.circular(8));

      // Drop shadow for card
      canvas.drawRRect(
        cardRect.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withValues(alpha: isDark ? 0.4 : 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      if (card is NoteCard) {
        final bg = _parseHex(card.colorHex);
        canvas.drawRRect(cardRect, Paint()..color = bg);
        canvas.drawRRect(
          cardRect,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // Header bar line
        final headerPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(card.x + 12, card.y + 16, card.width * 0.6, 6),
            const Radius.circular(3),
          ),
          headerPaint,
        );

        // 2 content lines
        final bodyPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(card.x + 12, card.y + 32, card.width * 0.75, 4),
            const Radius.circular(2),
          ),
          bodyPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(card.x + 12, card.y + 42, card.width * 0.5, 4),
            const Radius.circular(2),
          ),
          bodyPaint,
        );
      } else if (card is ColorCard) {
        final surface = isDark ? const Color(0xFF1E222D) : Colors.white;
        canvas.drawRRect(cardRect, Paint()..color = surface);
        canvas.drawRRect(
          cardRect,
          Paint()
            ..color = isDark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // Swatches bar
        final swatches = card.colorsHex;
        if (swatches.isNotEmpty) {
          final swatchW = (card.width - 20) / swatches.length;
          final top = card.y + 32;
          final h = card.height - 44;

          for (int i = 0; i < swatches.length; i++) {
            final sColor = _parseHex(swatches[i], fallback: const Color(0xFF64748B));
            final sRect = RRect.fromRectAndRadius(
              Rect.fromLTWH(card.x + 10 + i * swatchW, top, swatchW - 4, h),
              const Radius.circular(4),
            );
            canvas.drawRRect(sRect, Paint()..color = sColor);
          }
        }
      } else if (card is ImageCard) {
        final surface = isDark ? const Color(0xFF1E222D) : Colors.white;
        canvas.drawRRect(cardRect, Paint()..color = surface);
        canvas.drawRRect(
          cardRect,
          Paint()
            ..color = const Color(0xFF3B82F6).withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Inner placeholder image area
        final innerRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(card.x + 8, card.y + 8, card.width - 16, card.height - 32),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          innerRect,
          Paint()..color = isDark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0),
        );
      } else if (card is LinkCard) {
        final surface = isDark ? const Color(0xFF1E222D) : Colors.white;
        canvas.drawRRect(cardRect, Paint()..color = surface);
        canvas.drawRRect(
          cardRect,
          Paint()
            ..color = const Color(0xFF3B82F6).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Top thumbnail area
        final topRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(card.x + 8, card.y + 8, card.width - 16, card.height * 0.5),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          topRect,
          Paint()..color = isDark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0),
        );
      } else if (card is SubBoardCard) {
        final surface = isDark ? const Color(0xFF1E222D) : Colors.white;
        canvas.drawRRect(cardRect, Paint()..color = surface);
        canvas.drawRRect(
          cardRect,
          Paint()
            ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        canvas.drawRRect(
          cardRect,
          Paint()..color = isDark ? const Color(0xFF2E3545) : const Color(0xFFCBD5E1),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniCanvasPreviewPainter oldDelegate) {
    return oldDelegate.cards != cards ||
        oldDelegate.arrows != arrows ||
        oldDelegate.contentBounds != contentBounds ||
        oldDelegate.isDark != isDark;
  }
}
