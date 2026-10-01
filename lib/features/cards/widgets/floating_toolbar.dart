import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Floating left toolbar dock inspired by Milanote.
/// Provides quick 1-click creation of Note Cards, Image Cards, Color Swatches,
/// Paste from clipboard, and Arrow connection mode.
class FloatingToolbar extends StatelessWidget {
  final VoidCallback onAddNote;
  final VoidCallback onAddImage;
  final VoidCallback onAddColor;
  final VoidCallback? onAddLink;
  final VoidCallback? onAddSubBoard;
  final VoidCallback? onPaste;
  final bool isArrowMode;
  final VoidCallback? onToggleArrowMode;

  const FloatingToolbar({
    super.key,
    required this.onAddNote,
    required this.onAddImage,
    required this.onAddColor,
    this.onAddLink,
    this.onAddSubBoard,
    this.onPaste,
    this.isArrowMode = false,
    this.onToggleArrowMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockBg = (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface)
        .withValues(alpha: 0.92);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: dockBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tool 1: Note Card
            _ToolbarToolButton(
              icon: Icons.sticky_note_2_rounded,
              label: 'Catatan',
              tooltip: 'Tambah Catatan Baru',
              onTap: onAddNote,
            ),
            const SizedBox(height: 6),

            // Tool 2: Image Card
            _ToolbarToolButton(
              icon: Icons.image_rounded,
              label: 'Gambar',
              tooltip: 'Tambah Gambar (Pilih File atau Seret)',
              onTap: onAddImage,
            ),
            const SizedBox(height: 6),

            // Tool 3: Color Swatch Card
            _ToolbarToolButton(
              icon: Icons.palette_rounded,
              label: 'Warna',
              tooltip: 'Tambah Palet Swatch Warna',
              onTap: onAddColor,
            ),
            const SizedBox(height: 6),

            // Tool 4: Link Card (US-006)
            if (onAddLink != null) ...[
              _ToolbarToolButton(
                icon: Icons.link_rounded,
                label: 'Tautan',
                tooltip: 'Tambah Bookmark Tautan Web',
                onTap: onAddLink!,
              ),
              const SizedBox(height: 6),
            ],

            // Tool 5: Sub-Board Card (US-009)
            if (onAddSubBoard != null) ...[
              _ToolbarToolButton(
                icon: Icons.folder_special_rounded,
                label: 'Papan',
                tooltip: 'Tambah Sub-Board Bersarang',
                onTap: onAddSubBoard!,
              ),
              const SizedBox(height: 6),
            ],

            // Divider
            Container(
              width: 30,
              height: 1,
              color: borderColor,
              margin: const EdgeInsets.symmetric(vertical: 4),
            ),

            // Tool 6: Paste from Clipboard
            if (onPaste != null) ...[
              _ToolbarToolButton(
                icon: Icons.content_paste_rounded,
                label: 'Tempel',
                tooltip: 'Tempel dari Clipboard (Ctrl+V / Cmd+V)',
                onTap: onPaste!,
              ),
              const SizedBox(height: 6),
            ],

            // Tool 7: Arrow Connection Mode
            if (onToggleArrowMode != null)
              _ToolbarToolButton(
                icon: Icons.arrow_right_alt_rounded,
                label: 'Panah',
                tooltip: isArrowMode ? 'Matikan Mode Panah' : 'Mode Buat Panah Relasi',
                isActive: isArrowMode,
                onTap: onToggleArrowMode!,
              ),
          ],
        ),
      );
  }
}

class _ToolbarToolButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolbarToolButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_ToolbarToolButton> createState() => _ToolbarToolButtonState();
}

class _ToolbarToolButtonState extends State<_ToolbarToolButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = AppColors.accentPrimary.withValues(alpha: 0.2);
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: widget.isActive
                  ? activeBg
                  : (_isHovered ? hoverBg : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isActive
                    ? AppColors.accentPrimary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 19,
                  color: widget.isActive
                      ? AppColors.accentPrimary
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: widget.isActive
                        ? AppColors.accentPrimary
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
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
