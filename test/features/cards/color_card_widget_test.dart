import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/color_card.dart';
import 'package:localboard/features/cards/widgets/color_card_widget.dart';

void main() {
  testWidgets('ColorCardWidget renders color swatches, hex text, and title', (tester) async {
    final colorCard = ColorCard(
      id: 'color-test-1',
      x: 0,
      y: 0,
      title: 'Palet Pastel Studio',
      colorsHex: const ['#2C3E50', '#E74C3C', '#3498DB'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    String? updatedTitle;
    List<String>? updatedColors;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 160,
            child: ColorCardWidget(
              card: colorCard,
              isSelected: true,
              onTitleChanged: (t) => updatedTitle = t,
              onColorsChanged: (c) => updatedColors = c,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Palet Pastel Studio'), findsOneWidget);
    expect(find.text('#2C3E50'), findsOneWidget);
    expect(find.text('#E74C3C'), findsOneWidget);
    expect(find.text('#3498DB'), findsOneWidget);

    // Edit title
    await tester.enterText(find.byType(TextField).first, 'Palet Baru');
    expect(updatedTitle, equals('Palet Baru'));

    // Tap add swatch button
    final addBtn = find.byIcon(Icons.add_rounded);
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pump();

    expect(updatedColors, isNotNull);
    expect(updatedColors!.length, equals(4));
  });
}
