import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import '../../../core/theme/app_colors.dart';
import '../../cards/models/base_card.dart';
import '../../cards/models/connector_arrow.dart';
import '../../storage/data/asset_manager.dart';
import 'pdf_generator.dart';

/// Modal dialog allowing art students to configure PDF export settings (US-012 part 2 & PKG-03).
class PdfExportDialog extends StatefulWidget {
  final String boardTitle;
  final String boardId;
  final List<BaseCard> cards;
  final List<ConnectorArrow> arrows;
  final AssetManager? assetManager;
  final bool isDark;

  const PdfExportDialog({
    super.key,
    required this.boardTitle,
    required this.boardId,
    required this.cards,
    required this.arrows,
    this.assetManager,
    this.isDark = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String boardTitle,
    required String boardId,
    required List<BaseCard> cards,
    required List<ConnectorArrow> arrows,
    AssetManager? assetManager,
    bool isDark = true,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PdfExportDialog(
        boardTitle: boardTitle,
        boardId: boardId,
        cards: cards,
        arrows: arrows,
        assetManager: assetManager,
        isDark: isDark,
      ),
    );
  }

  @override
  State<PdfExportDialog> createState() => _PdfExportDialogState();
}

class _PdfExportDialogState extends State<PdfExportDialog> {
  PdfExportMode _mode = PdfExportMode.singlePagePoster;
  PdfPageFormat _format = PdfPageFormat.a4;
  bool _isLandscape = true;
  bool _isGenerating = false;

  Future<void> _handleSavePdf() async {
    setState(() => _isGenerating = true);

    try {
      final bytes = await PdfGenerator.generatePdfBytes(
        boardTitle: widget.boardTitle,
        cards: widget.cards,
        arrows: widget.arrows,
        mode: _mode,
        pageFormat: _format,
        isLandscape: _isLandscape,
        boardId: widget.boardId,
        assetManager: widget.assetManager,
      );

      final sanitizedTitle = widget.boardTitle.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\u00A0-\uFFFF-]'),
        '_',
      );
      final defaultFileName = '${sanitizedTitle}_moodboard.pdf';

      final result = await FilePicker.saveFile(
        dialogTitle: 'Simpan Dokumen Moodboard PDF',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (mounted) {
        if (result != null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dokumen PDF berhasil disimpan: $defaultFileName'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.accentSuccess,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor PDF: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: bg,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ekspor Dokumen PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'Pilih format poster atau multi-halaman siap cetak',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Export Mode Selection (Poster vs Multi-page)
              const Text(
                'Format Tampilan PDF:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ModeOptionTile(
                      title: 'Poster 1 Lembar',
                      subtitle: 'Semua kartu di 1 halaman utuh',
                      icon: Icons.aspect_ratio_rounded,
                      isSelected: _mode == PdfExportMode.singlePagePoster,
                      isDark: widget.isDark,
                      onTap: () => setState(() => _mode = PdfExportMode.singlePagePoster),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeOptionTile(
                      title: 'Multi-Halaman',
                      subtitle: 'Katalog terstruktur per kartu',
                      icon: Icons.auto_stories_rounded,
                      isSelected: _mode == PdfExportMode.multiPageCatalog,
                      isDark: widget.isDark,
                      onTap: () => setState(() => _mode = PdfExportMode.multiPageCatalog),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Paper Size Selection (A4 vs A3)
              const Text(
                'Ukuran Kertas:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PdfPageFormat>(
                segments: const [
                  ButtonSegment(
                    value: PdfPageFormat.a4,
                    label: Text('Kertas A4 (Standar)'),
                    icon: Icon(Icons.description_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: PdfPageFormat.a3,
                    label: Text('Kertas A3 (Poster Besar)'),
                    icon: Icon(Icons.newspaper_rounded, size: 16),
                  ),
                ],
                selected: {_format},
                onSelectionChanged: (val) {
                  if (val.isNotEmpty) setState(() => _format = val.first);
                },
              ),
              const SizedBox(height: 16),

              // 3. Orientation Selection (Landscape vs Portrait)
              const Text(
                'Orientasi Halaman:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Lanskap (Mendatar)'),
                    icon: Icon(Icons.stay_primary_landscape_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Potret (Tegak)'),
                    icon: Icon(Icons.stay_primary_portrait_rounded, size: 16),
                  ),
                ],
                selected: {_isLandscape},
                onSelectionChanged: (val) {
                  if (val.isNotEmpty) setState(() => _isLandscape = val.first);
                },
              ),
              const SizedBox(height: 16),

              // Summary info card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Menyertakan ${widget.cards.length} kartu seni visual dengan resolusi vektor siap cetak.',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          icon: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download_rounded, size: 18),
          label: Text(_isGenerating ? 'Membuat PDF...' : 'Simpan Berkas PDF'),
          onPressed: _isGenerating ? null : _handleSavePdf,
        ),
      ],
    );
  }
}

class _ModeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? Border.all(color: AppColors.accentPrimary, width: 1.5)
        : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.accentPrimary
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.accentPrimary
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
