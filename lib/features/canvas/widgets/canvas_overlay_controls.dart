import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../controller/canvas_controller.dart';

/// Floating overlay controls widget displaying the zoom percentage,
/// zoom in/out buttons, reset zoom, fit-to-view, and local autosave indicator.
class CanvasOverlayControls extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback? onFitToView;
  final bool isSaving;
  final String? lastSavedMessage;

  const CanvasOverlayControls({
    super.key,
    required this.controller,
    this.onFitToView,
    this.isSaving = false,
    this.lastSavedMessage = 'Tersimpan di lokal',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.darkSurfaceElevated.withValues(alpha: 0.92)
        : AppColors.lightSurface.withValues(alpha: 0.95);

    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
            children: [
              // Autosave Status Pill
              if (lastSavedMessage != null)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSaving ? AppColors.accentWarning : AppColors.accentSuccess,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSaving ? 'Menyimpan...' : lastSavedMessage!,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Zoom Navigation Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom Out Button
                    _ControlButton(
                      tooltip: 'Perkecil (Zoom Out)',
                      icon: Icons.remove_rounded,
                      onPressed: () {
                        final size = MediaQuery.of(context).size;
                        controller.zoomOut(focalPoint: Offset(size.width / 2, size.height / 2));
                      },
                    ),

                    // Reset Zoom (Pill Percentage)
                    Tooltip(
                      message: 'Reset Zoom (100%)',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final size = MediaQuery.of(context).size;
                          controller.resetZoom(focalPoint: Offset(size.width / 2, size.height / 2));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text(
                            controller.zoomPercentageString,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Zoom In Button
                    _ControlButton(
                      tooltip: 'Perbesar (Zoom In)',
                      icon: Icons.add_rounded,
                      onPressed: () {
                        final size = MediaQuery.of(context).size;
                        controller.zoomIn(focalPoint: Offset(size.width / 2, size.height / 2));
                      },
                    ),

                    const SizedBox(width: 2),
                    Container(
                      width: 1,
                      height: 16,
                      color: borderColor,
                    ),
                    const SizedBox(width: 2),

                    // Fit to View Button
                    _ControlButton(
                      tooltip: 'Pas ke Tampilan (Fit to View)',
                      icon: Icons.fit_screen_rounded,
                      onPressed: onFitToView,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
  }
}

class _ControlButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              icon,
              size: 17,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
