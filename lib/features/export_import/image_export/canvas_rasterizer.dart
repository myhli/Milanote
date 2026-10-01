import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bezier_math.dart';
import '../../cards/models/base_card.dart';
import '../../cards/models/color_card.dart';
import '../../cards/models/connector_arrow.dart';
import '../../cards/models/image_card.dart';
import '../../cards/models/note_card.dart';

/// Offscreen canvas rasterizer rendering vector cards, swatches, notes, and arrows
/// into a high-resolution PNG image at 1x, 2x, or 3x scale.
class CanvasRasterizer {
  /// Rasterizes [cards] and [arrows] within [bounds] at [scale] factor (1.0, 2.0, 3.0).
  /// Returns raw PNG image bytes.
  static Future<Uint8List> rasterizeToPng({
    required List<BaseCard> cards,
    required List<ConnectorArrow> arrows,
    required Rect bounds,
    double scale = 1.0,
    bool isDark = true,
    Color? backgroundColor,
  }) async {
    final int pixelWidth = (bounds.width * scale).ceil().clamp(1, 16384);
    final int pixelHeight = (bounds.height * scale).ceil().clamp(1, 16384);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelWidth.toDouble(), pixelHeight.toDouble()),
    );

    // Apply scale and coordinate origin translation
    canvas.scale(scale, scale);
    canvas.translate(-bounds.left, -bounds.top);

    // 1. Paint Solid Studio Background
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkCanvasBackground : AppColors.lightCanvasBackground);
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(bounds, bgPaint);

    // 2. Paint Connector Arrows
    _paintArrows(canvas, arrows, cards, isDark);

    // 3. Paint Cards (sorted by z-index ascending)
    final sortedCards = List<BaseCard>.from(cards)..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final card in sortedCards) {
      _paintCard(canvas, card, isDark);
    }

    // 4. Convert picture to image and encode to PNG
    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelWidth, pixelHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Gagal mengonversi kanvas ke format gambar PNG');
    }

    return byteData.buffer.asUint8List();
  }

  static void _paintArrows(
    Canvas canvas,
    List<ConnectorArrow> arrows,
    List<BaseCard> cards,
    bool isDark,
  ) {
    final cardMap = {for (var c in cards) c.id: c};

    for (final arrow in arrows) {
      final startCard = cardMap[arrow.startCardId];
      final endCard = cardMap[arrow.endCardId];
      if (startCard == null || endCard == null) continue;

      final startPos = BezierMath.getAnchorOffset(startCard.bounds, arrow.startAnchor);
      final endPos = BezierMath.getAnchorOffset(endCard.bounds, arrow.endAnchor);

      final color = _parseColor(arrow.colorHex, isDark ? Colors.white70 : Colors.black87);
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = arrow.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      Path path;
      switch (arrow.style) {
        case ArrowStyle.straight:
          path = BezierMath.computeStraightPath(start: startPos, end: endPos);
          break;
        case ArrowStyle.orthogonal:
          path = BezierMath.computeOrthogonalPath(
            start: startPos,
            end: endPos,
            startAnchor: arrow.startAnchor,
            endAnchor: arrow.endAnchor,
          );
          break;
        case ArrowStyle.curved:
          path = BezierMath.computeCurvedBezierPath(
            start: startPos,
            end: endPos,
            startAnchor: arrow.startAnchor,
            endAnchor: arrow.endAnchor,
          );
          break;
      }

      canvas.drawPath(path, linePaint);

      // Arrowhead
      if (arrow.head == ArrowHead.end || arrow.head == ArrowHead.both) {
        final arrowHeadPath = BezierMath.computeArrowHeadPath(
          tip: endPos,
          fromPoint: startPos,
        );
        final headPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawPath(arrowHeadPath, headPaint);
      }
    }
  }

  static void _paintCard(Canvas canvas, BaseCard card, bool isDark) {
    final cardRect = card.bounds;
    final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(12));

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);

    if (card is NoteCard) {
      _paintNoteCard(canvas, card, rrect, isDark);
    } else if (card is ColorCard) {
      _paintColorCard(canvas, card, rrect, isDark);
    } else if (card is ImageCard) {
      _paintImageCard(canvas, card, rrect, isDark);
    } else {
      _paintGenericCard(canvas, card, rrect, isDark);
    }
  }

  static void _paintNoteCard(
    Canvas canvas,
    NoteCard card,
    RRect rrect,
    bool isDark,
  ) {
    final noteBg = _parseColor(card.colorHex, isDark ? AppColors.darkSurface : Colors.white);
    final fillPaint = Paint()..color = noteBg;
    canvas.drawRRect(rrect, fillPaint);

    final borderPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Title
    final textTheme = isDark ? Colors.black87 : Colors.black87; // Pastel notes use dark text
    final titlePainter = TextPainter(
      text: TextSpan(
        text: card.title,
        style: TextStyle(
          color: textTheme,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: card.width - 24);

    titlePainter.paint(canvas, Offset(card.x + 12, card.y + 12));

    // Content or checklist
    if (card.isChecklistMode && card.checklists.isNotEmpty) {
      double curY = card.y + 40;
      for (final item in card.checklists.take(6)) {
        final boxPaint = Paint()
          ..color = item.isDone ? const Color(0xFF10B981) : Colors.black26
          ..style = item.isDone ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(card.x + 14, curY + 2, 12, 12),
            const Radius.circular(3),
          ),
          boxPaint,
        );

        final itemPainter = TextPainter(
          text: TextSpan(
            text: item.text,
            style: TextStyle(
              color: item.isDone ? Colors.black45 : textTheme,
              fontSize: 12,
              decoration: item.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        )..layout(maxWidth: card.width - 48);

        itemPainter.paint(canvas, Offset(card.x + 32, curY));
        curY += 20;
      }
    } else if (card.content.isNotEmpty) {
      final bodyPainter = TextPainter(
        text: TextSpan(
          text: card.content,
          style: TextStyle(
            color: textTheme.withValues(alpha: 0.8),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 6,
        ellipsis: '...',
      )..layout(maxWidth: card.width - 24);

      bodyPainter.paint(canvas, Offset(card.x + 12, card.y + 38));
    }
  }

  static void _paintColorCard(
    Canvas canvas,
    ColorCard card,
    RRect rrect,
    bool isDark,
  ) {
    final bgPaint = Paint()..color = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: card.title,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: card.width - 24);

    titlePainter.paint(canvas, Offset(card.x + 12, card.y + 10));

    // Swatches row
    final count = card.colorsHex.length.clamp(1, 8);
    final availableWidth = card.width - 24;
    final swatchWidth = (availableWidth - (count - 1) * 6) / count;

    for (int i = 0; i < count; i++) {
      final hex = card.colorsHex[i];
      final col = _parseColor(hex, Colors.grey);
      final sLeft = card.x + 12 + i * (swatchWidth + 6);
      final sRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(sLeft, card.y + 36, swatchWidth, card.height - 48),
        const Radius.circular(6),
      );

      final sPaint = Paint()..color = col;
      canvas.drawRRect(sRect, sPaint);

      // HEX text on swatch if space permits
      if (swatchWidth > 36) {
        final hexPainter = TextPainter(
          text: TextSpan(
            text: hex.replaceAll('#', ''),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        hexPainter.paint(
          canvas,
          Offset(
            sLeft + (swatchWidth - hexPainter.width) / 2,
            card.y + card.height - 24,
          ),
        );
      }
    }
  }

  static void _paintImageCard(
    Canvas canvas,
    ImageCard card,
    RRect rrect,
    bool isDark,
  ) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF1E222B) : const Color(0xFFE2E8F0);
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Camera Placeholder Icon & Caption
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '🖼️',
        style: const TextStyle(fontSize: 28),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        card.center.dx - iconPainter.width / 2,
        card.center.dy - iconPainter.height / 2 - 12,
      ),
    );

    if (card.caption.isNotEmpty) {
      final captionPainter = TextPainter(
        text: TextSpan(
          text: card.caption,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: card.width - 20);

      captionPainter.paint(
        canvas,
        Offset(card.center.dx - captionPainter.width / 2, card.center.dy + 16),
      );
    }
  }

  static void _paintGenericCard(
    Canvas canvas,
    BaseCard card,
    RRect rrect,
    bool isDark,
  ) {
    final bgPaint = Paint()..color = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    canvas.drawRRect(rrect, bgPaint);
  }

  static Color _parseColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }
}
