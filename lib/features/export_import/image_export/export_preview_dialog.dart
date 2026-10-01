import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bounding_box_calculator.dart';
import '../../cards/models/base_card.dart';
import '../../cards/models/connector_arrow.dart';
import 'canvas_rasterizer.dart';

/// Interactive modal dialog allowing users to preview canvas bounds and export
/// high-resolution PNG images at 1x, 2x, or 3x scale.
class ExportPreviewDialog extends StatefulWidget {
  final List<BaseCard> cards;
  final List<ConnectorArrow> arrows;
  final String boardTitle;
  final bool isDark;

  const ExportPreviewDialog({
    super.key,
    required this.cards,
    required this.arrows,
    required this.boardTitle,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required List<BaseCard> cards,
    required List<ConnectorArrow> arrows,
    required String boardTitle,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ExportPreviewDialog(
        cards: cards,
        arrows: arrows,
        boardTitle: boardTitle,
        isDark: isDark,
      ),
    );
  }

  @override
  State<ExportPreviewDialog> createState() => _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends State<ExportPreviewDialog> {
  late final Rect _bounds;
  double _selectedScale = 2.0; // Default to 2x (Retina)
  Uint8List? _previewBytes;
  bool _isRendering = true;
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _bounds = BoundingBoxCalculator.calculate(cards: widget.cards);
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    setState(() {
      _isRendering = true;
      _statusMessage = null;
    });

    try {
      final bytes = await CanvasRasterizer.rasterizeToPng(
        cards: widget.cards,
        arrows: widget.arrows,
        bounds: _bounds,
        scale: 1.0, // Fast preview scale
        isDark: widget.isDark,
      );

      if (mounted) {
        setState(() {
          _previewBytes = bytes;
          _isRendering = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRendering = false;
          _statusMessage = 'Gagal memuat pratinjau: $e';
        });
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final pngBytes = await CanvasRasterizer.rasterizeToPng(
        cards: widget.cards,
        arrows: widget.arrows,
        bounds: _bounds,
        scale: _selectedScale,
        isDark: widget.isDark,
      );

      final cleanTitle = widget.boardTitle
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName = '${cleanTitle}_${_selectedScale.toInt()}x.png';

      final result = await FilePicker.saveFile(
        dialogTitle: 'Simpan Gambar Moodboard',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['png'],
        bytes: pngBytes,
      );

      if (mounted) {
        if (result != null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gambar berhasil disimpan: $fileName'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.accentSuccess,
            ),
          );
        } else {
          setState(() {
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Gagal menyimpan gambar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final widthPx = (_bounds.width * _selectedScale).round();
    final heightPx = (_bounds.height * _selectedScale).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.accentPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ekspor Gambar Resolusi Tinggi (PNG)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Otomatis membungkus seluruh elemen kanvas dengan batas proporsional',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                height: 1,
              ),
              const SizedBox(height: 16),

              // Image Preview Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF11141A) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Center(
                    child: _isRendering
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 12),
                              Text(
                                'Merender pratinjau kanvas...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          )
                        : _previewBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: InteractiveViewer(
                                  maxScale: 3.0,
                                  minScale: 0.5,
                                  child: Image.memory(
                                    _previewBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : Text(
                                _statusMessage ?? 'Gagal memuat pratinjau',
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Resolution / Scale Selector & Dimensions
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilihan Resolusi & Skala:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<double>(
                        segments: const [
                          ButtonSegment(
                            value: 1.0,
                            label: Text('1x (Standar)'),
                          ),
                          ButtonSegment(
                            value: 2.0,
                            label: Text('2x (Retina)'),
                          ),
                          ButtonSegment(
                            value: 3.0,
                            label: Text('3x (Ultra HD)'),
                          ),
                        ],
                        selected: {_selectedScale},
                        onSelectionChanged: (set) {
                          setState(() => _selectedScale = set.first);
                        },
                      ),
                    ],
                  ),

                  // Dimension summary badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Dimensi Ekspor:',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$widthPx × $heightPx px',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_statusMessage != null && !_isRendering) ...[
                const SizedBox(height: 8),
                Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Gambar (PNG)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
