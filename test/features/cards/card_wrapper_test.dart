import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/widgets/card_wrapper.dart';

void main() {
  testWidgets('CardWrapper handles selection, movement drag, and resize', (tester) async {
    final card = NoteCard(
      id: 'wrap-test-1',
      x: 100,
      y: 100,
      width: 250,
      height: 200,
      title: 'Wrapper Test Card',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool selected = false;
    double? movedX, movedY;
    double? resizedW, resizedH;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CardWrapper(
                card: card,
                isSelected: true,
                canvasScale: 1.0,
                onSelect: () => selected = true,
                onMove: (nx, ny) {
                  movedX = nx;
                  movedY = ny;
                },
                onResize: (nw, nh) {
                  resizedW = nw;
                  resizedH = nh;
                },
                child: const Text('Inner Content'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Inner Content'), findsOneWidget);

    // Tap to select
    await tester.tap(find.text('Inner Content'));
    expect(selected, isTrue);

    // Drag to move
    await tester.drag(find.text('Inner Content'), const Offset(50, 40));
    expect(movedX, isNotNull);
    expect(movedY, isNotNull);
    expect(movedX!, greaterThan(100.0));
    expect(movedY!, greaterThan(100.0));

    // Drag resize handle at bottom-right
    final resizeHandle = find.byKey(const Key('card_resize_handle'));
    expect(resizeHandle, findsOneWidget);
    await tester.drag(resizeHandle, const Offset(30, 20));
    expect(resizedW, isNotNull);
    expect(resizedH, isNotNull);
    expect(resizedW!, greaterThan(250.0));
    expect(resizedH!, greaterThan(200.0));
  });
}
