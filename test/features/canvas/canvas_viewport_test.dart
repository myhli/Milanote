import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/app/theme.dart';
import 'package:localboard/features/canvas/controller/canvas_controller.dart';
import 'package:localboard/features/canvas/widgets/canvas_overlay_controls.dart';
import 'package:localboard/features/canvas/widgets/canvas_viewport.dart';

void main() {
  group('CanvasViewport and OverlayControls', () {
    late CanvasController controller;

    setUp(() {
      controller = CanvasController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders CanvasViewport, InteractiveViewer, and initial 100% zoom pill',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: StudioTheme.darkTheme,
          home: Scaffold(
            body: CanvasViewport(
              controller: controller,
              content: const SizedBox(
                width: 1000,
                height: 800,
                child: Center(child: Text('Canvas Content Area')),
              ),
            ),
          ),
        ),
      );

      // Verify layers exist
      expect(find.byType(CanvasViewport), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(CanvasOverlayControls), findsOneWidget);
      expect(find.text('Canvas Content Area'), findsOneWidget);

      // Zoom indicator shows 100%
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Tersimpan di lokal'), findsOneWidget);
    });

    testWidgets('tapping zoom in and zoom out updates zoom pill percentage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: StudioTheme.darkTheme,
          home: Scaffold(
            body: CanvasViewport(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);

      // Tap Zoom In button (+)
      final zoomInFinder = find.byTooltip('Perbesar (Zoom In)');
      expect(zoomInFinder, findsOneWidget);
      await tester.tap(zoomInFinder);
      await tester.pumpAndSettle();

      expect(controller.scale, greaterThan(1.0));
      expect(find.text('115%'), findsOneWidget);

      // Tap Zoom Out button (-)
      final zoomOutFinder = find.byTooltip('Perkecil (Zoom Out)');
      expect(zoomOutFinder, findsOneWidget);
      await tester.tap(zoomOutFinder);
      await tester.pumpAndSettle();

      expect(controller.scale, closeTo(1.0, 0.01));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('tapping zoom pill resets zoom to 100%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: StudioTheme.darkTheme,
          home: Scaffold(
            body: CanvasViewport(
              controller: controller,
            ),
          ),
        ),
      );

      // Zoom in twice
      final zoomInFinder = find.byTooltip('Perbesar (Zoom In)');
      await tester.tap(zoomInFinder);
      await tester.pumpAndSettle();
      await tester.tap(zoomInFinder);
      await tester.pumpAndSettle();

      expect(controller.scale, greaterThan(1.2));

      // Tap zoom percentage text pill to reset zoom
      final resetFinder = find.byTooltip('Reset Zoom (100%)');
      expect(resetFinder, findsOneWidget);
      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      expect(controller.scale, closeTo(1.0, 0.001));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('tapping Fit to View invokes fitToView logic', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: StudioTheme.darkTheme,
          home: Scaffold(
            body: CanvasViewport(
              controller: controller,
              contentBounds: const Rect.fromLTWH(0, 0, 1500, 1200),
            ),
          ),
        ),
      );

      final fitFinder = find.byTooltip('Pas ke Tampilan (Fit to View)');
      expect(fitFinder, findsOneWidget);
      await tester.tap(fitFinder);
      await tester.pumpAndSettle();

      // Viewport scale should have adjusted to fit 1500x1200
      expect(controller.scale, isNot(closeTo(1.0, 0.001)));
    });
  });
}
