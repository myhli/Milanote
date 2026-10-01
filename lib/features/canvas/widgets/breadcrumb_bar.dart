import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Single node in the hierarchical canvas breadcrumb trail (US-009 & FR-12).
@immutable
class BreadcrumbItem {
  final String boardId;
  final String title;

  const BreadcrumbItem({
    required this.boardId,
    required this.title,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreadcrumbItem &&
          runtimeType == other.runtimeType &&
          boardId == other.boardId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(boardId, title);
}

/// Horizontal breadcrumb navigation bar allowing art students to jump back
/// up the board hierarchy with a single click (e.g. Proyek Utama > Karakter > Senjata).
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final ValueChanged<BreadcrumbItem> onNavigate;

  const BreadcrumbBar({
    super.key,
    required this.items,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            _BreadcrumbChip(
              item: items[i],
              isCurrent: i == items.length - 1,
              isDark: isDark,
              onTap: () => onNavigate(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatefulWidget {
  final BreadcrumbItem item;
  final bool isCurrent;
  final bool isDark;
  final VoidCallback onTap;

  const _BreadcrumbChip({
    required this.item,
    required this.isCurrent,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_BreadcrumbChip> createState() => _BreadcrumbChipState();
}

class _BreadcrumbChipState extends State<_BreadcrumbChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isCurrent) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          widget.item.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: widget.isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.item.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isHovered
                  ? AppColors.accentPrimary
                  : (widget.isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
