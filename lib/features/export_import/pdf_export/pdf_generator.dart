import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/bounding_box_calculator.dart';
import '../../cards/models/base_card.dart';
import '../../cards/models/color_card.dart';
import '../../cards/models/connector_arrow.dart';
import '../../cards/models/image_card.dart';
import '../../cards/models/link_card.dart';
import '../../cards/models/note_card.dart';
import '../../cards/models/subboard_card.dart';
import '../../storage/data/asset_manager.dart';

/// PDF Export Layout Modes (US-012 part 2 & PKG-03).
enum PdfExportMode {
  singlePagePoster,
  multiPageCatalog,
}

/// PDF Document Generator producing print-ready visual moodboards (US-012 & FR-17).
class PdfGenerator {
  /// Generates PDF document bytes for the specified canvas cards and arrows.
  static Future<Uint8List> generatePdfBytes({
    required String boardTitle,
    required List<BaseCard> cards,
    required List<ConnectorArrow> arrows,
    required PdfExportMode mode,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool isLandscape = true,
    String? boardId,
    AssetManager? assetManager,
  }) async {
    final pdf = pw.Document(
      title: boardTitle,
      author: 'LocalBoard Studio',
      creator: 'LocalBoard (Local-First Infinite Canvas)',
    );

    final finalFormat = isLandscape ? pageFormat.landscape : pageFormat.portrait;

    // Pre-load all image bytes for offline embedding in PDF
    final imageBytesMap = <String, Uint8List>{};
    if (boardId != null && assetManager != null) {
      for (final card in cards) {
        if (card is ImageCard && card.assetUuid.isNotEmpty) {
          final file = await assetManager.getAssetFile(
            boardId: boardId,
            relativePath: card.assetUuid,
          );
          if (await file.exists()) {
            imageBytesMap[card.assetUuid] = await file.readAsBytes();
          }
        } else if (card is LinkCard && card.coverAssetUuid.isNotEmpty) {
          final file = await assetManager.getAssetFile(
            boardId: boardId,
            relativePath: card.coverAssetUuid,
          );
          if (await file.exists()) {
            imageBytesMap[card.coverAssetUuid] = await file.readAsBytes();
          }
        }
      }
    }

    if (mode == PdfExportMode.singlePagePoster) {
      _buildSinglePagePoster(
        pdf: pdf,
        format: finalFormat,
        boardTitle: boardTitle,
        cards: cards,
        arrows: arrows,
        imageBytesMap: imageBytesMap,
      );
    } else {
      _buildMultiPageCatalog(
        pdf: pdf,
        format: finalFormat,
        boardTitle: boardTitle,
        cards: cards,
        imageBytesMap: imageBytesMap,
      );
    }

    return pdf.save();
  }

  /// Builds a single-page poster fitting all canvas cards proportionally.
  static void _buildSinglePagePoster({
    required pw.Document pdf,
    required PdfPageFormat format,
    required String boardTitle,
    required List<BaseCard> cards,
    required List<ConnectorArrow> arrows,
    required Map<String, Uint8List> imageBytesMap,
  }) {
    final bounds = BoundingBoxCalculator.calculate(cards: cards, padding: 30);
    final dateStr = DateFormat('d MMMM yyyy, HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          final contentW = format.availableWidth;
          final contentH = format.availableHeight - 48; // Leave space for header

          final scaleX = contentW / (bounds.width > 0 ? bounds.width : contentW);
          final scaleY = contentH / (bounds.height > 0 ? bounds.height : contentH);
          final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.05, 1.5);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        boardTitle,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'LocalBoard Studio Moodboard - Ekspor Poster',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    dateStr,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Canvas Cards Placement
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    for (final card in cards)
                      pw.Positioned(
                        left: (card.x - bounds.left) * fitScale,
                        top: (card.y - bounds.top) * fitScale,
                        child: pw.SizedBox(
                          width: card.width * fitScale,
                          height: card.height * fitScale,
                          child: _buildPdfCard(card, imageBytesMap, scale: fitScale),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a multi-page document catalog presenting each visual element in structured grid sections.
  static void _buildMultiPageCatalog({
    required pw.Document pdf,
    required PdfPageFormat format,
    required String boardTitle,
    required List<BaseCard> cards,
    required Map<String, Uint8List> imageBytesMap,
  }) {
    final dateStr = DateFormat('d MMMM yyyy').format(DateTime.now());

    // Page 1: Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo600,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'LB',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  boardTitle,
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Katalog Desain & Dokumen Visual Moodboard',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Total Elemen: ${cards.length} kartu   |   Tanggal: $dateStr',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Subsequent Pages: Cards in organized grid (up to 4 cards per page)
    const chunkSize = 4;
    for (int i = 0; i < cards.length; i += chunkSize) {
      final end = (i + chunkSize < cards.length) ? i + chunkSize : cards.length;
      final pageCards = cards.sublist(i, end);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      boardTitle,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Halaman ${(i ~/ chunkSize) + 2}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 12),

                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      for (final card in pageCards)
                        _buildPdfCard(card, imageBytesMap, scale: 1.0, isCatalogMode: true),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  /// Builds a rendered PDF representation for a given card model.
  static pw.Widget _buildPdfCard(
    BaseCard card,
    Map<String, Uint8List> imageBytesMap, {
    double scale = 1.0,
    bool isCatalogMode = false,
  }) {
    if (card is NoteCard) {
      PdfColor bg = PdfColors.yellow50;
      if (card.colorHex.contains('FEF9C3')) bg = PdfColors.yellow100;
      if (card.colorHex.contains('DCFCE7')) bg = PdfColors.green100;
      if (card.colorHex.contains('E0F2FE')) bg = PdfColors.blue100;
      if (card.colorHex.contains('FFEDD5')) bg = PdfColors.orange100;
      if (card.colorHex.contains('F3F4F6')) bg = PdfColors.grey200;

      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: bg,
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (card.title.isNotEmpty) ...[
              pw.Text(
                card.title,
                style: pw.TextStyle(
                  fontSize: isCatalogMode ? 12 : 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                maxLines: 2,
              ),
              pw.SizedBox(height: 4),
            ],
            if (card.content.isNotEmpty)
              pw.Expanded(
                child: pw.Text(
                  card.content,
                  style: pw.TextStyle(fontSize: isCatalogMode ? 9.5 : 7),
                  maxLines: isCatalogMode ? 6 : 4,
                ),
              ),
            if (card.checklists.isNotEmpty)
              for (final item in card.checklists.take(3))
                pw.Row(
                  children: [
                    pw.Text(item.isDone ? '[x] ' : '[ ] ',
                        style: const pw.TextStyle(fontSize: 7)),
                    pw.Expanded(
                      child: pw.Text(item.text,
                          style: const pw.TextStyle(fontSize: 7), maxLines: 1),
                    ),
                  ],
                ),
          ],
        ),
      );
    } else if (card is ColorCard) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              card.title.isNotEmpty ? card.title : 'Palet Warna',
              style: pw.TextStyle(
                fontSize: isCatalogMode ? 11 : 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Expanded(
              child: pw.Row(
                children: [
                  for (final hex in card.colorsHex)
                    pw.Expanded(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: pw.BoxDecoration(
                          color: _parseHexToPdfColor(hex),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            hex,
                            style: const pw.TextStyle(fontSize: 5, color: PdfColors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (card is ImageCard) {
      final bytes = imageBytesMap[card.assetUuid];

      return pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Expanded(
              child: bytes != null
                  ? pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 6,
                      child: pw.Image(
                        pw.MemoryImage(bytes),
                        fit: pw.BoxFit.cover,
                      ),
                    )
                  : pw.Center(
                      child: pw.Text('Gambar', style: const pw.TextStyle(fontSize: 8)),
                    ),
            ),
            if (card.caption.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(3),
                child: pw.Text(
                  card.caption,
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800),
                  maxLines: 1,
                ),
              ),
          ],
        ),
      );
    } else if (card is LinkCard) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              card.siteName.isNotEmpty ? card.siteName : card.url,
              style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.indigo600),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              card.title.isNotEmpty ? card.title : card.url,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              maxLines: 2,
            ),
            if (card.description.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                card.description,
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                maxLines: 2,
              ),
            ],
          ],
        ),
      );
    } else if (card is SubBoardCard) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo50,
          border: pw.Border.all(color: PdfColors.indigo200, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '[Sub-Board]',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.indigo800),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              card.title,
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '${card.cardCount} kartu di dalam papan',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ],
        ),
      );
    }

    return pw.Container();
  }

  static PdfColor _parseHexToPdfColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      final intVal = int.parse('FF$clean', radix: 16);
      return PdfColor.fromInt(intVal);
    } catch (_) {
      return PdfColors.grey400;
    }
  }
}
