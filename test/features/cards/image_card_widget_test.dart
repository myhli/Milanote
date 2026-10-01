import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/image_card.dart';
import 'package:localboard/features/cards/widgets/image_card_widget.dart';

void main() {
  testWidgets('ImageCardWidget renders caption and placeholder when no file', (tester) async {
    final imageCard = ImageCard(
      id: 'img-test-1',
      x: 0,
      y: 0,
      assetUuid: '',
      caption: 'Sketsa Pensil 2B',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    String? updatedCaption;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 240,
            child: ImageCardWidget(
              card: imageCard,
              isSelected: true,
              onCaptionChanged: (val) => updatedCaption = val,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Sketsa Pensil 2B'), findsOneWidget);
    expect(find.text('Seret gambar atau klik ganti'), findsOneWidget);

    // Edit caption
    await tester.enterText(find.byType(TextField), 'Keterangan Baru');
    expect(updatedCaption, equals('Keterangan Baru'));
  });
}
