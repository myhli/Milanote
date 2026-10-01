import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/widgets/floating_toolbar.dart';

void main() {
  testWidgets('FloatingToolbar renders tools and triggers callbacks', (tester) async {
    bool addNoteTapped = false;
    bool addImageTapped = false;
    bool addColorTapped = false;
    bool toggleArrowTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingToolbar(
                onAddNote: () => addNoteTapped = true,
                onAddImage: () => addImageTapped = true,
                onAddColor: () => addColorTapped = true,
                onToggleArrowMode: () => toggleArrowTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Gambar'), findsOneWidget);
    expect(find.text('Warna'), findsOneWidget);
    expect(find.text('Panah'), findsOneWidget);

    await tester.tap(find.text('Catatan'));
    expect(addNoteTapped, isTrue);

    await tester.tap(find.text('Gambar'));
    expect(addImageTapped, isTrue);

    await tester.tap(find.text('Warna'));
    expect(addColorTapped, isTrue);

    await tester.tap(find.text('Panah'));
    expect(toggleArrowTapped, isTrue);
  });
}
