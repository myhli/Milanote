import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/bezier_math.dart';
import '../../cards/models/base_card.dart';
import '../../cards/models/color_card.dart';
import '../../cards/models/connector_arrow.dart';
import '../../cards/models/image_card.dart';
import '../../cards/models/link_card.dart';
import '../../cards/models/note_card.dart';
import '../../cards/models/subboard_card.dart';
import '../../cards/widgets/arrow_painter.dart';
import '../../cards/widgets/card_wrapper.dart';
import '../../cards/widgets/color_card_widget.dart';
import '../../cards/widgets/image_card_widget.dart';
import '../../cards/widgets/link_card_widget.dart';
import '../../cards/widgets/note_card_widget.dart';
import '../../cards/widgets/subboard_card_widget.dart';
import '../../storage/data/asset_manager.dart';
import '../controller/canvas_controller.dart';

/// Canvas layer rendering all visual cards, relational connector arrows,
/// and handling drag-and-drop from OS file explorer as well as clipboard image paste.
class CanvasCardsLayer extends StatefulWidget {
  final List<BaseCard> cards;
  final List<ConnectorArrow> arrows;
  final String? selectedCardId;
  final String? selectedArrowId;
  final CanvasController controller;
  final String boardId;
  final AssetManager? assetManager;
  final ValueChanged<String?> onSelectCard;
  final void Function(String id, double x, double y) onMoveCard;
  final void Function(String id, double x, double y, double startX, double startY)? onMoveCardEnd;
  final void Function(String id, double w, double h) onResizeCard;
  final void Function(String id, double w, double h, double startW, double startH)? onResizeCardEnd;
  final ValueChanged<String> onDeleteCard;
  final ValueChanged<String> onDuplicateCard;
  final ValueChanged<String> onBringToFront;
  final ValueChanged<BaseCard> onUpdateCard;
  final ValueChanged<ConnectorArrow> onAddArrow;
  final ValueChanged<String> onDeleteArrow;
  final ValueChanged<String?> onSelectArrow;
  final ValueChanged<ConnectorArrow>? onUpdateArrow;
  final ValueChanged<BaseCard>? onCardCreated;
  final ValueChanged<String>? onOpenSubBoard;

  const CanvasCardsLayer({
    super.key,
    required this.cards,
    required this.arrows,
    this.selectedCardId,
    this.selectedArrowId,
    required this.controller,
    required this.boardId,
    this.assetManager,
    required this.onSelectCard,
    required this.onMoveCard,
    this.onMoveCardEnd,
    required this.onResizeCard,
    this.onResizeCardEnd,
    required this.onDeleteCard,
    required this.onDuplicateCard,
    required this.onBringToFront,
    required this.onUpdateCard,
    required this.onAddArrow,
    required this.onDeleteArrow,
    required this.onSelectArrow,
    this.onUpdateArrow,
    this.onCardCreated,
    this.onOpenSubBoard,
  });

  @override
  State<CanvasCardsLayer> createState() => _CanvasCardsLayerState();
}

class _CanvasCardsLayerState extends State<CanvasCardsLayer> {
  // Arrow drawing in progress
  String? _drawingStartCardId;
  CardAnchor? _drawingStartAnchor;
  Offset? _drawingCurrentCanvasPos;

  // Virtual Canvas Dimension
  static const double virtualCanvasSize = 20000.0;

  Map<String, BaseCard> get _cardMap => {
        for (final c in widget.cards) c.id: c,
      };

  void _handleArrowDragStart(String cardId, CardAnchor anchor, Offset canvasPos) {
    setState(() {
      _drawingStartCardId = cardId;
      _drawingStartAnchor = anchor;
      _drawingCurrentCanvasPos = canvasPos;
    });
  }

  void _handleArrowDragUpdate(Offset canvasPos) {
    setState(() {
      _drawingCurrentCanvasPos = canvasPos;
    });
  }

  void _handleArrowDragEnd(Offset endScreenPos) {
    if (_drawingStartCardId == null ||
        _drawingStartAnchor == null ||
        _drawingCurrentCanvasPos == null) {
      _clearArrowDrag();
      return;
    }

    final dropPoint = _drawingCurrentCanvasPos!;
    // Find target card that encloses the drop point
    BaseCard? targetCard;
    for (final card in widget.cards) {
      if (card.id != _drawingStartCardId && card.bounds.inflate(20).contains(dropPoint)) {
        targetCard = card;
        break;
      }
    }

    if (targetCard != null) {
      // Find closest anchor on target card
      CardAnchor closestAnchor = CardAnchor.left;
      double minDistance = double.infinity;

      for (final anchor in CardAnchor.values) {
        final anchorOffset = BezierMath.getAnchorOffset(targetCard.bounds, anchor);
        final dist = (anchorOffset - dropPoint).distance;
        if (dist < minDistance) {
          minDistance = dist;
          closestAnchor = anchor;
        }
      }

      final newArrow = ConnectorArrow(
        id: const Uuid().v4(),
        startCardId: _drawingStartCardId!,
        endCardId: targetCard.id,
        startAnchor: _drawingStartAnchor!,
        endAnchor: closestAnchor,
        style: ArrowStyle.curved,
        head: ArrowHead.end,
      );

      widget.onAddArrow(newArrow);
    }

    _clearArrowDrag();
  }

  void _clearArrowDrag() {
    setState(() {
      _drawingStartCardId = null;
      _drawingStartAnchor = null;
      _drawingCurrentCanvasPos = null;
    });
  }

  /// Handles OS file explorer drag & drop of images onto the canvas.
  Future<void> _handleFileDrop(DropDoneDetails details) async {
    final screenPos = details.localPosition;
    final canvasDropPos = widget.controller.screenToCanvas(screenPos);

    for (final file in details.files) {
      final ext = file.name.split('.').last.toLowerCase();
      if (!['png', 'jpg', 'jpeg', 'webp'].contains(ext)) continue;

      final bytes = await file.readAsBytes();
      String assetPath = file.path;

      if (widget.assetManager != null) {
        assetPath = await widget.assetManager!.saveAsset(
          boardId: widget.boardId,
          bytes: bytes,
          fileExtension: ext,
        );
      }

      final newImageCard = ImageCard(
        id: const Uuid().v4(),
        x: canvasDropPos.dx,
        y: canvasDropPos.dy,
        width: 320,
        height: 240,
        assetUuid: assetPath,
        caption: file.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onCardCreated?.call(newImageCard);
    }
  }

  /// Handles clipboard paste (Ctrl+V / Cmd+V).
  Future<void> handleClipboardPaste() async {
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        String assetPath = '';
        if (widget.assetManager != null) {
          assetPath = await widget.assetManager!.saveAsset(
            boardId: widget.boardId,
            bytes: imageBytes,
            fileExtension: 'png',
          );
        }

        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        final screenCenter = Offset(size.width / 2, size.height / 2);
        final canvasPos = widget.controller.screenToCanvas(screenCenter);

        final newImageCard = ImageCard(
          id: const Uuid().v4(),
          x: canvasPos.dx - 160,
          y: canvasPos.dy - 120,
          width: 320,
          height: 240,
          assetUuid: assetPath,
          caption: 'Gambar dari Clipboard',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        widget.onCardCreated?.call(newImageCard);
      }
    } catch (e) {
      debugPrint('Error pasting from clipboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final startCard = _drawingStartCardId != null ? _cardMap[_drawingStartCardId] : null;
    final previewStart = (startCard != null && _drawingStartAnchor != null)
        ? BezierMath.getAnchorOffset(startCard.bounds, _drawingStartAnchor!)
        : null;

    // Sort cards by zIndex so higher zIndex cards render above lower ones
    final sortedCards = List<BaseCard>.from(widget.cards)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    Offset? selectedArrowMidpoint;
    final selectedArrow = widget.selectedArrowId != null
        ? widget.arrows.cast<ConnectorArrow?>().firstWhere(
            (a) => a?.id == widget.selectedArrowId,
            orElse: () => null,
          )
        : null;

    if (selectedArrow != null) {
      final startCard = _cardMap[selectedArrow.startCardId];
      final endCard = _cardMap[selectedArrow.endCardId];
      if (startCard != null && endCard != null) {
        final startPt = BezierMath.getAnchorOffset(startCard.bounds, selectedArrow.startAnchor);
        final endPt = BezierMath.getAnchorOffset(endCard.bounds, selectedArrow.endAnchor);
        selectedArrowMidpoint = BezierMath.getArrowMidpoint(
          start: startPt,
          end: endPt,
          startAnchor: selectedArrow.startAnchor,
          endAnchor: selectedArrow.endAnchor,
          style: selectedArrow.style,
        );
      }
    }

    return DropTarget(
      onDragDone: _handleFileDrop,
      child: SizedBox(
        width: virtualCanvasSize,
        height: virtualCanvasSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Layer 0: Empty Canvas Background Interaction (Arrow hit-test, Deselect on tap, Double-tap quick note)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final canvasPos = details.localPosition;
                  // Hit-test connector arrows from top to bottom
                  for (final arrow in widget.arrows.reversed) {
                    final startCard = _cardMap[arrow.startCardId];
                    final endCard = _cardMap[arrow.endCardId];
                    if (startCard == null || endCard == null) continue;

                    final startPt = BezierMath.getAnchorOffset(startCard.bounds, arrow.startAnchor);
                    final endPt = BezierMath.getAnchorOffset(endCard.bounds, arrow.endAnchor);

                    if (BezierMath.isPointNearArrow(
                      point: canvasPos,
                      start: startPt,
                      end: endPt,
                      startAnchor: arrow.startAnchor,
                      endAnchor: arrow.endAnchor,
                      style: arrow.style,
                    )) {
                      widget.onSelectArrow(arrow.id);
                      widget.onSelectCard(null);
                      return;
                    }
                  }

                  widget.onSelectCard(null);
                  widget.onSelectArrow(null);
                },
                onDoubleTapDown: (details) {
                  // Double-click on empty canvas creates quick note (PRD US-004 & Design Considerations)
                  final canvasPos = details.localPosition;
                  final newNote = NoteCard(
                    id: const Uuid().v4(),
                    x: (canvasPos.dx - 140).clamp(0.0, virtualCanvasSize - 280),
                    y: (canvasPos.dy - 110).clamp(0.0, virtualCanvasSize - 220),
                    width: 280,
                    height: 220,
                    zIndex: 100,
                    title: 'Catatan Cepat',
                    content: '',
                    colorHex: '#FEF9C3',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  widget.onCardCreated?.call(newNote);
                },
                onDoubleTap: () {},
                child: Container(color: Colors.transparent),
              ),
            ),

            // Layer 1: Dynamic Relational Connector Arrows
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ArrowPainter(
                    arrows: widget.arrows,
                    cardMap: _cardMap,
                    selectedArrowId: widget.selectedArrowId,
                    previewStartPoint: previewStart,
                    previewEndPoint: _drawingCurrentCanvasPos,
                  ),
                ),
              ),
            ),

              // Layer 2: All Cards wrapped with Draggable Card Wrapper
              for (final card in sortedCards)
                CardWrapper(
                  key: ValueKey(card.id),
                  card: card,
                  isSelected: card.id == widget.selectedCardId,
                  canvasScale: widget.controller.scale,
                  onSelect: () {
                    widget.onSelectCard(card.id);
                    widget.onSelectArrow(null);
                  },
                  onMove: (nx, ny) => widget.onMoveCard(card.id, nx, ny),
                  onMoveEnd: (fx, fy, sx, sy) =>
                      widget.onMoveCardEnd?.call(card.id, fx, fy, sx, sy),
                  onResize: (nw, nh) => widget.onResizeCard(card.id, nw, nh),
                  onResizeEnd: (fw, fh, sw, sh) =>
                      widget.onResizeCardEnd?.call(card.id, fw, fh, sw, sh),
                  onDelete: () => widget.onDeleteCard(card.id),
                  onDuplicate: () => widget.onDuplicateCard(card.id),
                  onBringToFront: () => widget.onBringToFront(card.id),
                  onArrowDragStart: _handleArrowDragStart,
                  onArrowDragUpdate: _handleArrowDragUpdate,
                  onArrowDragEnd: _handleArrowDragEnd,
                  child: _buildCardContent(card),
                ),

            // Layer 3: Interactive Floating Arrow Customization Toolbar (US-008 & ARW-01..04)
            if (selectedArrow != null && selectedArrowMidpoint != null)
              Positioned(
                left: (selectedArrowMidpoint.dx - 180).clamp(10.0, virtualCanvasSize - 370),
                top: (selectedArrowMidpoint.dy - 56).clamp(10.0, virtualCanvasSize - 60),
                child: _buildArrowToolbar(selectedArrow),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildCardContent(BaseCard card) {
    final isSelected = card.id == widget.selectedCardId;

    if (card is NoteCard) {
      return NoteCardWidget(
        card: card,
        isSelected: isSelected,
        onTitleChanged: (t) => widget.onUpdateCard(card.copyWith(title: t)),
        onContentChanged: (c) => widget.onUpdateCard(card.copyWith(content: c)),
        onColorChanged: (hex) => widget.onUpdateCard(card.copyWith(colorHex: hex)),
        onChecklistsChanged: (items) =>
            widget.onUpdateCard(card.copyWith(checklists: items)),
        onToggleMode: () => widget.onUpdateCard(
          card.copyWith(isChecklistMode: !card.isChecklistMode),
        ),
      );
    } else if (card is ImageCard) {
      return ImageCardWidget(
        card: card,
        boardId: widget.boardId,
        assetManager: widget.assetManager,
        isSelected: isSelected,
        onCaptionChanged: (c) => widget.onUpdateCard(card.copyWith(caption: c)),
      );
    } else if (card is ColorCard) {
      return ColorCardWidget(
        card: card,
        isSelected: isSelected,
        onTitleChanged: (t) => widget.onUpdateCard(card.copyWith(title: t)),
        onColorsChanged: (colors) =>
            widget.onUpdateCard(card.copyWith(colorsHex: colors)),
      );
    } else if (card is LinkCard) {
      return LinkCardWidget(
        card: card,
        boardId: widget.boardId,
        assetManager: widget.assetManager,
        isSelected: isSelected,
        onCardChanged: (updated) => widget.onUpdateCard(updated),
      );
    } else if (card is SubBoardCard) {
      return SubBoardCardWidget(
        card: card,
        isSelected: isSelected,
        onCardChanged: (updated) => widget.onUpdateCard(updated),
        onOpenSubBoard: () => widget.onOpenSubBoard?.call(card.targetBoardId),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildArrowToolbar(ConnectorArrow arrow) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Style: Straight
          _ArrowToolbarBtn(
            key: const Key('arrow_style_straight_btn'),
            icon: Icons.horizontal_rule_rounded,
            tooltip: 'Garis Lurus',
            isSelected: arrow.style == ArrowStyle.straight,
            onTap: () => widget.onUpdateArrow?.call(arrow.copyWith(style: ArrowStyle.straight)),
          ),
          const SizedBox(width: 2),
          // Style: Curved Bezier
          _ArrowToolbarBtn(
            key: const Key('arrow_style_curved_btn'),
            icon: Icons.gesture_rounded,
            tooltip: 'Garis Lengkung (Bezier)',
            isSelected: arrow.style == ArrowStyle.curved,
            onTap: () => widget.onUpdateArrow?.call(arrow.copyWith(style: ArrowStyle.curved)),
          ),
          const SizedBox(width: 2),
          // Style: Orthogonal
          _ArrowToolbarBtn(
            key: const Key('arrow_style_orthogonal_btn'),
            icon: Icons.turn_right_rounded,
            tooltip: 'Garis Siku',
            isSelected: arrow.style == ArrowStyle.orthogonal,
            onTap: () => widget.onUpdateArrow?.call(arrow.copyWith(style: ArrowStyle.orthogonal)),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: 16, color: isDark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0)),
          const SizedBox(width: 4),

          // Head: None
          _ArrowToolbarBtn(
            key: const Key('arrow_head_none_btn'),
            icon: Icons.remove_rounded,
            tooltip: 'Tanpa Panah',
            isSelected: arrow.head == ArrowHead.none,
            onTap: () => widget.onUpdateArrow?.call(arrow.copyWith(head: ArrowHead.none)),
          ),
          const SizedBox(width: 2),
          // Head: 1 Way
          _ArrowToolbarBtn(
            key: const Key('arrow_head_end_btn'),
            icon: Icons.arrow_forward_rounded,
            tooltip: 'Panah 1 Arah',
            isSelected: arrow.head == ArrowHead.end,
            onTap: () => widget.onUpdateArrow?.call(arrow.copyWith(head: ArrowHead.end)),
          ),
          const SizedBox(width: 2),
          // Head: 2 Way
          _ArrowToolbarBtn(
            key: const Key('arrow_head_both_btn'),
            icon: Icons.sync_alt_rounded,
            tooltip: 'Panah 2 Arah',
            isSelected: arrow.head == ArrowHead.both,
            onTap: () => widget.onUpdateArrow?.call(arrow.copyWith(head: ArrowHead.both)),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: 16, color: isDark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0)),
          const SizedBox(width: 6),

          // Palette colors
          for (final hex in const ['#64748B', '#3B82F6', '#EF4444', '#10B981', '#F59E0B']) ...[
            GestureDetector(
              onTap: () => widget.onUpdateArrow?.call(arrow.copyWith(colorHex: hex)),
              child: Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: arrow.colorHex.toUpperCase() == hex.toUpperCase()
                        ? const Color(0xFF3B82F6)
                        : Colors.black.withValues(alpha: 0.2),
                    width: arrow.colorHex.toUpperCase() == hex.toUpperCase() ? 2 : 1,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(width: 2),
          Container(width: 1, height: 16, color: isDark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0)),
          const SizedBox(width: 4),

          // Delete Arrow Button
          IconButton(
            key: const Key('delete_arrow_btn'),
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
            tooltip: 'Hapus Panah',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => widget.onDeleteArrow(arrow.id),
          ),
        ],
      ),
    );
  }
}

class _ArrowToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArrowToolbarBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
