import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../storage/data/asset_manager.dart';
import '../models/image_card.dart';

/// Interactive UI widget rendering an Image Card with local sandboxed asset loading,
/// inline caption editing, and a full-resolution Lightbox modal.
class ImageCardWidget extends StatefulWidget {
  final ImageCard card;
  final String boardId;
  final AssetManager? assetManager;
  final bool isSelected;
  final ValueChanged<String>? onCaptionChanged;
  final VoidCallback? onReplaceImage;

  const ImageCardWidget({
    super.key,
    required this.card,
    this.boardId = 'default',
    this.assetManager,
    this.isSelected = false,
    this.onCaptionChanged,
    this.onReplaceImage,
  });

  @override
  State<ImageCardWidget> createState() => _ImageCardWidgetState();
}

class _ImageCardWidgetState extends State<ImageCardWidget> {
  late final TextEditingController _captionController;
  File? _resolvedFile;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.card.caption);
    _isLoading = widget.card.assetUuid.isNotEmpty;
    _resolveImageFile();
  }

  @override
  void didUpdateWidget(covariant ImageCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.caption != widget.card.caption &&
        _captionController.text != widget.card.caption) {
      _captionController.text = widget.card.caption;
    }
    if (oldWidget.card.assetUuid != widget.card.assetUuid) {
      _resolveImageFile();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _resolveImageFile() async {
    if (widget.card.assetUuid.isEmpty) {
      if (mounted) {
        setState(() {
          _resolvedFile = null;
          _isLoading = false;
        });
      } else {
        _resolvedFile = null;
        _isLoading = false;
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    } else {
      _isLoading = true;
    }

    try {
      if (widget.assetManager != null) {
        final file = await widget.assetManager!.getAssetFile(
          boardId: widget.boardId,
          relativePath: widget.card.assetUuid,
        );
        if (mounted) {
          setState(() {
            _resolvedFile = file;
            _isLoading = false;
          });
        }
      } else {
        // Fallback: direct file path
        final file = File(widget.card.assetUuid);
        if (mounted) {
          setState(() {
            _resolvedFile = file.existsSync() ? file : null;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedFile = null;
          _isLoading = false;
        });
      }
    }
  }

  void _openLightbox(BuildContext context) {
    if (_resolvedFile == null) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                maxScale: 5.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_resolvedFile!, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              if (widget.card.caption.isNotEmpty)
                Positioned(
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.card.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Area
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: GestureDetector(
                onDoubleTap: () => _openLightbox(context),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isLoading)
                      const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_resolvedFile != null && _resolvedFile!.existsSync())
                      // High-performance image loading
                      Image.file(
                        _resolvedFile!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      )
                    else
                      Container(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seret gambar atau klik ganti',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Quick Action Overlay: Lightbox button & replace button on hover/selection
                    if (widget.isSelected && _resolvedFile != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _OverlayIconButton(
                              icon: Icons.fullscreen_rounded,
                              tooltip: 'Pratinjau Layar Penuh (Lightbox)',
                              onPressed: () => _openLightbox(context),
                            ),
                            const SizedBox(width: 4),
                            if (widget.onReplaceImage != null)
                              _OverlayIconButton(
                                icon: Icons.refresh_rounded,
                                tooltip: 'Ganti Gambar',
                                onPressed: widget.onReplaceImage!,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Caption Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: TextField(
              controller: _captionController,
              onChanged: widget.onCaptionChanged,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Tambah keterangan gambar...',
                hintStyle: TextStyle(
                  fontSize: 11.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _OverlayIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: Colors.white),
        tooltip: tooltip,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
        onPressed: onPressed,
      ),
    );
  }
}
