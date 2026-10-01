import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/app/app.dart';
import 'package:localboard/features/cards/widgets/floating_toolbar.dart';
import 'package:localboard/features/canvas/widgets/canvas_cards_layer.dart';
import 'package:localboard/features/canvas/widgets/canvas_overlay_controls.dart';
import 'package:localboard/features/canvas/widgets/canvas_viewport.dart';
import 'package:localboard/features/gallery/presentation/gallery_screen.dart';

void main() {
  testWidgets('BoardCanvasScreen initializes properly with cards, arrows, floating dock, and theme switcher',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: LocalBoardApp(home: BoardCanvasScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify core canvas components exist
    expect(find.byType(CanvasViewport), findsOneWidget);
    expect(find.byType(CanvasOverlayControls), findsOneWidget);
    expect(find.byType(CanvasCardsLayer), findsOneWidget);
    expect(find.byType(FloatingToolbar), findsOneWidget);
    expect(find.text('🎨 LocalBoard'), findsOneWidget);

    // Verify initial sample cards exist
    expect(find.text('🎨 Eksperimen Visual & Konsep'), findsOneWidget);
    expect(find.text('Palet Karakter Utama'), findsOneWidget);
    expect(find.text('Inspirasi Estetika Studio'), findsOneWidget);

    // Verify theme toggle button
    final themeToggleFinder = find.byTooltip('Beralih ke Studio Light');
    expect(themeToggleFinder, findsOneWidget);

    // Tap theme toggle (Dark -> Light)
    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();

    // Verify app switched to Studio Light
    expect(find.byTooltip('Beralih ke Studio Dark'), findsOneWidget);
    expect(find.byType(CanvasViewport), findsOneWidget);
  });

  testWidgets('LocalBoardApp defaults to GalleryScreen on launch (FR-1 & US-001)',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: LocalBoardApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Gallery Dashboard is the default entry screen
    expect(find.byType(GalleryScreen), findsOneWidget);
    expect(find.text('LocalBoard'), findsOneWidget);
    expect(find.text('Galeri Papan Studio'), findsOneWidget);
  });
}
