import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/canvas/widgets/breadcrumb_bar.dart';

void main() {
  group('BreadcrumbBar Tests (ADV-03)', () {
    testWidgets('renders trail of ancestors and active current board', (tester) async {
      final items = [
        const BreadcrumbItem(boardId: 'b-root', title: 'Proyek Akhir'),
        const BreadcrumbItem(boardId: 'b-sub1', title: 'Desain Karakter'),
        const BreadcrumbItem(boardId: 'b-sub2', title: 'Senjata & Zirah'),
      ];

      BreadcrumbItem? tappedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreadcrumbBar(
              items: items,
              onNavigate: (item) => tappedItem = item,
            ),
          ),
        ),
      );

      expect(find.text('Proyek Akhir'), findsOneWidget);
      expect(find.text('Desain Karakter'), findsOneWidget);
      expect(find.text('Senjata & Zirah'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));

      // Tapping ancestor triggers onNavigate
      await tester.tap(find.text('Proyek Akhir'));
      await tester.pumpAndSettle();

      expect(tappedItem?.boardId, 'b-root');
    });
  });
}
