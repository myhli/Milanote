import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/subboard_card.dart';

/// Interactive card widget representing a nested Sub-Board on the canvas (US-009 & FR-12).
/// Displays folder visual styling, card count badge, and triggers opening the child canvas.
class SubBoardCardWidget extends StatefulWidget {
  final SubBoardCard card;
  final bool isSelected;
  final ValueChanged<SubBoardCard>? onCardChanged;
  final VoidCallback? onOpenSubBoard;

  const SubBoardCardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.onCardChanged,
    this.onOpenSubBoard,
  });

  @override
  State<SubBoardCardWidget> createState() => _SubBoardCardWidgetState();
}

class _SubBoardCardWidgetState extends State<SubBoardCardWidget> {
  bool _isHovered = false;
  late final TextEditingController _titleController;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
  }

  @override
  void didUpdateWidget(covariant SubBoardCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.title != widget.card.title && !_isEditingTitle) {
      _titleController.text = widget.card.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _finishEditingTitle() {
    setState(() => _isEditingTitle = false);
    final trimmed = _titleController.text.trim();
    if (trimmed.isNotEmpty && trimmed != widget.card.title) {
      widget.onCardChanged?.call(widget.card.copyWith(
        title: trimmed,
        updatedAt: DateTime.now(),
      ));
    } else {
      _titleController.text = widget.card.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Parse accent color
    Color accentColor = const Color(0xFF6366F1); // Indigo default
    try {
      final hex = widget.card.colorHex.replaceAll('#', '');
      accentColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onDoubleTap: widget.onOpenSubBoard,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? accentColor : borderColor,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 5 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Tab / Folder visual banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  border: Border(
                    bottom: BorderSide(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.folder_special_rounded,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _isEditingTitle
                          ? TextField(
                              controller: _titleController,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _finishEditingTitle(),
                              onEditingComplete: _finishEditingTitle,
                            )
                          : GestureDetector(
                              onTap: () => setState(() => _isEditingTitle = true),
                              child: Text(
                                widget.card.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                    ),
                    // Card Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers_rounded,
                            size: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.card.cardCount} kartu',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sub-Board Description or prompt
                      Text(
                        widget.card.description.isNotEmpty
                            ? widget.card.description
                            : 'Papan terisolasi untuk mengelompokkan ide, studi konsep, atau aset karakter.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),

                      // Action button: "Buka Sub-Board"
                      Align(
                        alignment: Alignment.bottomRight,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: const Text(
                            'Buka Papan',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          onPressed: widget.onOpenSubBoard,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
