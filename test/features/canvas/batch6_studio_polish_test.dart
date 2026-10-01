import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/core/utils/bezier_math.dart';
import 'package:localboard/features/canvas/controller/board_state_notifier.dart';
import 'package:localboard/features/cards/models/color_card.dart';
import 'package:localboard/features/cards/models/connector_arrow.dart';
import 'package:localboard/features/cards/models/note_card.dart';
import 'package:localboard/features/cards/widgets/color_card_widget.dart';
import 'package:localboard/features/cards/widgets/note_card_widget.dart';
import 'package:localboard/features/gallery/presentation/widgets/board_mini_thumbnail.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/board_repository.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';
import 'package:localboard/features/storage/storage_providers.dart';

class _MockBoardRepository implements BoardRepository {
  final Map<String, BoardMetadata> metadataStore = {};
  final Map<String, CanvasData> canvasStore = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<BoardMetadata>> getBoards() async => metadataStore.values.toList();

  @override
  Future<BoardMetadata?> getBoardMetadata(String boardId) async =>
      metadataStore[boardId];

  @override
  Future<CanvasData?> getCanvasData(String boardId) async =>
      canvasStore[boardId];

  @override
  Future<void> saveBoard({
    required BoardMetadata metadata,
    required CanvasData canvasData,
  }) async {
    metadataStore[metadata.id] = metadata;
    canvasStore[metadata.id] = canvasData;
  }

  @override
  Future<void> updateMetadata(BoardMetadata metadata) async {
    metadataStore[metadata.id] = metadata;
  }

  @override
  Future<void> updateCanvasData(CanvasData canvasData) async {
    canvasStore[canvasData.boardId] = canvasData;
  }

  @override
  Future<void> deleteBoard(String boardId) async {
    metadataStore.remove(boardId);
    canvasStore.remove(boardId);
  }

  @override
  Future<BoardMetadata> duplicateBoard({
    required String sourceBoardId,
    required String newTitle,
  }) async {
    final meta = BoardMetadata(
      id: 'dup_$sourceBoardId',
      title: newTitle,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      cardCount: 0,
    );
    metadataStore[meta.id] = meta;
    return meta;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 6 Studio Polish - Note Card Rich Markdown Formatting', () {
    testWidgets('FormattingTextEditingController generates styled spans for headers and bullet points', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = FormattingTextEditingController(
                  text: '# Heading 1\n• Bullet Item\n**Bold Text**\n*Italic Text*',
                );
                final span = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  withComposing: false,
                );

                expect(span.children, isNotNull);
                expect(span.children!.isNotEmpty, isTrue);
                return const Text('done');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Format buttons inject markdown syntax into NoteCardWidget', (tester) async {
      final now = DateTime.now();
      final card = NoteCard(
        id: 'note_format_test',
        x: 100,
        y: 100,
        width: 260,
        height: 220,
        title: 'Project Brief',
        content: 'Design system draft',
        colorHex: '#FEF08A',
        createdAt: now,
        updatedAt: now,
      );

      String currentContent = card.content;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 260,
                child: NoteCardWidget(
                  card: card,
                  isSelected: true,
                  onContentChanged: (newContent) {
                    currentContent = newContent;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Heading button
      final headingBtn = find.byKey(const Key('format_heading_btn'));
      expect(headingBtn, findsOneWidget);
      await tester.tap(headingBtn);
      await tester.pumpAndSettle();
      expect(currentContent.contains('# Judul'), isTrue);

      // Bullet list button formats the currently selected text
      final bulletBtn = find.byKey(const Key('format_bullet_btn'));
      expect(bulletBtn, findsOneWidget);
      await tester.tap(bulletBtn);
      await tester.pumpAndSettle();
      expect(currentContent.contains('• Judul'), isTrue);
    });
  });

  group('Batch 6 Studio Polish - ColorCardWidget RGB Values & Copy', () {
    testWidgets('Displays RGB labels alongside HEX and handles 1-click clipboard copy', (tester) async {
      final now = DateTime.now();
      final card = ColorCard(
        id: 'color_test_1',
        x: 100,
        y: 100,
        width: 240,
        height: 200,
        title: 'Brand Palette',
        colorsHex: const ['#FF5733', '#33FF57'],
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                height: 240,
                child: ColorCardWidget(
                  card: card,
                  isSelected: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify HEX and RGB labels are displayed
      expect(find.text('#FF5733'), findsOneWidget);
      expect(find.text('255, 87, 51'), findsOneWidget);

      // Tap copy RGB button
      final copyRgbBtn = find.byKey(const Key('copy_rgb_0_btn'));
      expect(copyRgbBtn, findsOneWidget);
      await tester.tap(copyRgbBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('Batch 6 Studio Polish - Gallery BoardMiniThumbnail Preview', () {
    late _MockBoardRepository mockRepo;

    setUp(() {
      mockRepo = _MockBoardRepository();
    });

    testWidgets('BoardMiniThumbnail renders empty state placeholder gracefully', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 120,
                child: BoardMiniThumbnail(
                  boardId: 'empty_board',
                  isDark: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dashboard_customize_rounded), findsOneWidget);
      expect(find.text('Kanvas Kosong'), findsOneWidget);
    });

    testWidgets('BoardMiniThumbnail renders canvas preview painter with cards and arrows', (tester) async {
      final now = DateTime.now();
      final note = NoteCard(
        id: 'n1',
        x: 0,
        y: 0,
        width: 200,
        height: 150,
        title: 'Note 1',
        content: 'Hello',
        colorHex: '#FEF08A',
        createdAt: now,
        updatedAt: now,
      );
      final swatch = ColorCard(
        id: 'c1',
        x: 250,
        y: 50,
        width: 180,
        height: 120,
        title: 'Palette',
        colorsHex: const ['#E11D48', '#2563EB'],
        createdAt: now,
        updatedAt: now,
      );
      final arrow = const ConnectorArrow(
        id: 'a1',
        startCardId: 'n1',
        endCardId: 'c1',
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.curved,
        head: ArrowHead.end,
        colorHex: '#64748B',
      );

      final canvasData = CanvasData(
        boardId: 'sample_board',
        cards: [note.toJson(), swatch.toJson()],
        arrows: [arrow.toJson()],
        updatedAt: now,
      );

      mockRepo.canvasStore['sample_board'] = canvasData;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 220,
                height: 130,
                child: BoardMiniThumbnail(
                  boardId: 'sample_board',
                  isDark: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Batch 6 Studio Polish - Arrow Hit-Testing & Update Action', () {
    test('isPointNearArrow returns true for points close to straight arrow', () {
      const p1 = Offset(100, 100);
      const p2 = Offset(300, 100);

      // Point right on the line
      final onLine = BezierMath.isPointNearArrow(
        point: const Offset(200, 100),
        start: p1,
        end: p2,
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.straight,
        hitRadius: 12.0,
      );
      expect(onLine, isTrue);

      // Point slightly above line within threshold
      final nearLine = BezierMath.isPointNearArrow(
        point: const Offset(200, 106),
        start: p1,
        end: p2,
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.straight,
        hitRadius: 12.0,
      );
      expect(nearLine, isTrue);

      // Point far away from line
      final farLine = BezierMath.isPointNearArrow(
        point: const Offset(200, 150),
        start: p1,
        end: p2,
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.straight,
        hitRadius: 12.0,
      );
      expect(farLine, isFalse);
    });

    test('getArrowMidpoint returns reasonable center for arrow toolbar anchoring', () {
      const p1 = Offset(100, 100);
      const p2 = Offset(300, 100);
      final mid = BezierMath.getArrowMidpoint(
        start: p1,
        end: p2,
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.straight,
      );
      expect(mid.dx, 200);
      expect(mid.dy, 100);
    });

    testWidgets('UpdateArrowAction updates arrow and supports Undo/Redo in BoardStateNotifier', (tester) async {
      final mockRepo = _MockBoardRepository();
      const boardId = 'test_arrow_board';
      final now = DateTime.now();
      final originalArrow = const ConnectorArrow(
        id: 'test_arrow_1',
        startCardId: 'card_a',
        endCardId: 'card_b',
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.straight,
        head: ArrowHead.end,
        colorHex: '#64748B',
      );

      final meta = BoardMetadata(
        id: boardId,
        title: 'Arrow Board',
        createdAt: now,
        updatedAt: now,
        cardCount: 0,
      );
      final canvas = CanvasData(
        boardId: boardId,
        cards: const [],
        arrows: [originalArrow.toJson()],
        updatedAt: now,
      );
      mockRepo.metadataStore[boardId] = meta;
      mockRepo.canvasStore[boardId] = canvas;

      final container = ProviderContainer(
        overrides: [
          boardRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(boardStateNotifierProvider.notifier);
      await notifier.loadBoard(boardId);

      expect(container.read(boardStateNotifierProvider).arrows.first.style, ArrowStyle.straight);

      final updatedArrow = originalArrow.copyWith(
        style: ArrowStyle.curved,
        head: ArrowHead.both,
        colorHex: '#E11D48',
      );

      notifier.updateArrow(updatedArrow);

      expect(container.read(boardStateNotifierProvider).arrows.first.style, ArrowStyle.curved);
      expect(container.read(boardStateNotifierProvider).arrows.first.head, ArrowHead.both);
      expect(container.read(boardStateNotifierProvider).arrows.first.colorHex, '#E11D48');
      expect(container.read(boardStateNotifierProvider).canUndo, isTrue);

      // Undo
      notifier.undo();
      expect(container.read(boardStateNotifierProvider).arrows.first.style, ArrowStyle.straight);
      expect(container.read(boardStateNotifierProvider).arrows.first.head, ArrowHead.end);
      expect(container.read(boardStateNotifierProvider).canRedo, isTrue);

      // Redo
      notifier.redo();
      expect(container.read(boardStateNotifierProvider).arrows.first.style, ArrowStyle.curved);
      expect(container.read(boardStateNotifierProvider).arrows.first.head, ArrowHead.both);

      // Flush autosave debounce timer cleanly before disposing
      await tester.pump(const Duration(milliseconds: 600));
      container.dispose();
    });
  });
}
