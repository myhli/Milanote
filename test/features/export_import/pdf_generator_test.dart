import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/color_card.dart';
import 'package:localboard/features/cards/models/link_card.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/models/subboard_card.dart';
import 'package:localboard/features/export_import/pdf_export/pdf_generator.dart';
import 'package:pdf/pdf.dart';

void main() {
  group('PdfGenerator Tests (PKG-03 & US-012)', () {
    final now = DateTime.now();
    final sampleCards = [
      NoteCard(
        id: 'n1',
        x: 100,
        y: 100,
        width: 250,
        height: 180,
        title: 'Konsep Desain Grafis',
        content: 'Prinsip kontras dan ritme visual.',
        createdAt: now,
        updatedAt: now,
      ),
      ColorCard(
        id: 'c1',
        x: 400,
        y: 100,
        width: 260,
        height: 120,
        title: 'Palet Warna Harmonis',
        colorsHex: const ['#2C3E50', '#E74C3C', '#3498DB'],
        createdAt: now,
        updatedAt: now,
      ),
      LinkCard(
        id: 'l1',
        x: 100,
        y: 320,
        width: 280,
        height: 200,
        url: 'https://artstation.com/artist',
        title: 'Portofolio Artis',
        siteName: 'artstation.com',
        createdAt: now,
        updatedAt: now,
      ),
      SubBoardCard(
        id: 'sb1',
        x: 400,
        y: 320,
        width: 260,
        height: 160,
        targetBoardId: 'child_1',
        title: 'Sub-Board Studi Pose',
        cardCount: 5,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('generatePdfBytes produces valid PDF bytes for single-page poster', () async {
      final pdfBytes = await PdfGenerator.generatePdfBytes(
        boardTitle: 'Papan Uji Seni',
        cards: sampleCards,
        arrows: const [],
        mode: PdfExportMode.singlePagePoster,
        pageFormat: PdfPageFormat.a4,
        isLandscape: true,
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF files begin with '%PDF-'
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('generatePdfBytes produces valid PDF bytes for multi-page catalog', () async {
      final pdfBytes = await PdfGenerator.generatePdfBytes(
        boardTitle: 'Katalog Portofolio Seni',
        cards: sampleCards,
        arrows: const [],
        mode: PdfExportMode.multiPageCatalog,
        pageFormat: PdfPageFormat.a4,
        isLandscape: false,
      );

      expect(pdfBytes, isNotEmpty);
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });
  });
}
