import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/bounding_box_calculator.dart';
import '../features/cards/models/color_card.dart';
import '../features/cards/models/connector_arrow.dart';
import '../features/cards/models/image_card.dart';
import '../features/cards/models/link_card.dart';
import '../features/cards/models/note_card.dart';
import '../features/cards/models/subboard_card.dart';
import '../features/cards/widgets/floating_toolbar.dart';
import '../features/canvas/controller/board_state_notifier.dart';
import '../features/canvas/controller/canvas_controller.dart';
import '../features/canvas/widgets/breadcrumb_bar.dart';
import '../features/canvas/widgets/canvas_cards_layer.dart';
import '../features/canvas/widgets/canvas_viewport.dart';
import '../features/export_import/image_export/export_preview_dialog.dart';
import '../features/export_import/pdf_export/pdf_export_dialog.dart';
import '../features/gallery/presentation/gallery_screen.dart';
import '../features/storage/domain/autosave_service.dart';
import '../features/storage/domain/board_metadata.dart';
import '../features/storage/domain/canvas_data.dart';
import '../features/storage/storage_providers.dart';
import 'theme.dart';

/// Notifier for toggling between Studio Dark and Light themes (Riverpod 3.x).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Root application widget for LocalBoard.
/// Defaults to GalleryScreen (FR-1 & US-001) while allowing direct screen injection for testing.
class LocalBoardApp extends ConsumerWidget {
  final Widget? home;

  const LocalBoardApp({super.key, this.home});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'LocalBoard',
      debugShowCheckedModeBanner: false,
      theme: StudioTheme.lightTheme,
      darkTheme: StudioTheme.darkTheme,
      themeMode: themeMode,
      home: home ?? const GalleryScreen(),
    );
  }
}

/// Canvas screen coordinating cards, dynamic arrows, viewport navigation, and floating tools.
class BoardCanvasScreen extends ConsumerStatefulWidget {
  final String boardId;
  final List<BreadcrumbItem> breadcrumbs;

  const BoardCanvasScreen({
    super.key,
    this.boardId = 'default_board',
    this.breadcrumbs = const [],
  });

  @override
  ConsumerState<BoardCanvasScreen> createState() => _BoardCanvasScreenState();
}

class _BoardCanvasScreenState extends ConsumerState<BoardCanvasScreen> {
  late final CanvasController _canvasController;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _canvasController = CanvasController();

    // Zero-data-loss flush on app background or exit
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.detached) {
          ref.read(boardStateNotifierProvider.notifier).flushAutosave();
        }
      },
    );

    // Load active board in microtask
    Future.microtask(() async {
      final notifier = ref.read(boardStateNotifierProvider.notifier);
      await notifier.loadBoard(widget.boardId);

      final state = ref.read(boardStateNotifierProvider);
      if (widget.boardId == 'default_board' && state.cards.isEmpty) {
        _seedDefaultSampleData(notifier);
      }
    });
  }

  void _seedDefaultSampleData(BoardStateNotifier notifier) {
    final now = DateTime.now();
    const noteId = 'sample-note-1';
    const colorId = 'sample-color-1';
    const imageId = 'sample-image-1';

    notifier.addCard(
      NoteCard(
        id: noteId,
        x: 180,
        y: 160,
        width: 320,
        height: 290,
        zIndex: 1,
        title: '🎨 Eksperimen Visual & Konsep',
        content:
            'Kumpulkan referensi visual, susun palet warna, dan hubungkan ide antar-kartu secara bebas.',
        colorHex: '#FEF9C3',
        checklists: const [
          ChecklistItem(id: 'c1', text: 'Kumpulkan referensi seni studio', isDone: true),
          ChecklistItem(id: 'c2', text: 'Tentukan palet 5 warna harmonis', isDone: true),
          ChecklistItem(id: 'c3', text: 'Tarik garis panah relasi antar-kartu', isDone: false),
        ],
        isChecklistMode: true,
        createdAt: now,
        updatedAt: now,
      ),
      recordHistory: false,
    );

    notifier.addCard(
      ColorCard(
        id: colorId,
        x: 620,
        y: 160,
        width: 320,
        height: 140,
        zIndex: 2,
        title: 'Palet Karakter Utama',
        colorsHex: const ['#2C3E50', '#E74C3C', '#3498DB', '#F1C40F', '#1ABC9C'],
        createdAt: now,
        updatedAt: now,
      ),
      recordHistory: false,
    );

    notifier.addCard(
      ImageCard(
        id: imageId,
        x: 620,
        y: 340,
        width: 320,
        height: 230,
        zIndex: 3,
        assetUuid: '',
        caption: 'Inspirasi Estetika Studio',
        createdAt: now,
        updatedAt: now,
      ),
      recordHistory: false,
    );

    notifier.addArrow(
      const ConnectorArrow(
        id: 'sample-arrow-1',
        startCardId: noteId,
        endCardId: colorId,
        startAnchor: CardAnchor.right,
        endAnchor: CardAnchor.left,
        style: ArrowStyle.curved,
        head: ArrowHead.end,
        strokeWidth: 2.5,
      ),
      recordHistory: false,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _canvasController.dispose();
    super.dispose();
  }

  Offset _getViewportCenterInCanvas() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? MediaQuery.of(context).size;
    final screenCenter = Offset(size.width / 2, size.height / 2);
    return _canvasController.screenToCanvas(screenCenter);
  }

  void _handleAddNoteCard() {
    final center = _getViewportCenterInCanvas();
    final newCard = NoteCard(
      id: const Uuid().v4(),
      x: center.dx - 140,
      y: center.dy - 110,
      width: 280,
      height: 220,
      zIndex: 100,
      title: 'Catatan Baru',
      content: '',
      colorHex: '#FEF9C3',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(boardStateNotifierProvider.notifier).addCard(newCard);
  }

  Future<void> _handleAddImageCard() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final bytes = await file.readAsBytes();
      final assetManager = ref.read(assetManagerProvider);
      final ext = file.extension ?? 'png';

      final assetPath = await assetManager.saveAsset(
        boardId: widget.boardId,
        bytes: bytes,
        fileExtension: ext,
      );

      final center = _getViewportCenterInCanvas();
      final newCard = ImageCard(
        id: const Uuid().v4(),
        x: center.dx - 160,
        y: center.dy - 120,
        width: 320,
        height: 240,
        zIndex: 100,
        assetUuid: assetPath,
        caption: file.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(boardStateNotifierProvider.notifier).addCard(newCard);
    }
  }

  void _handleAddColorCard() {
    final center = _getViewportCenterInCanvas();
    final newCard = ColorCard(
      id: const Uuid().v4(),
      x: center.dx - 140,
      y: center.dy - 70,
      width: 280,
      height: 140,
      zIndex: 100,
      title: 'Palet Warna',
      colorsHex: const ['#2C3E50', '#E74C3C', '#3498DB', '#F1C40F'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(boardStateNotifierProvider.notifier).addCard(newCard);
  }

  Future<void> _handleAddLinkCard() async {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: const Text('Tambah Tautan Web',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan atau tempel URL tautan referensi visual:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link_rounded, size: 20),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
            child: const Text('Tambah Kartu'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final center = _getViewportCenterInCanvas();
      final newCard = LinkCard(
        id: const Uuid().v4(),
        x: center.dx - 150,
        y: center.dy - 130,
        width: 300,
        height: 260,
        zIndex: 100,
        url: result,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(boardStateNotifierProvider.notifier).addCard(newCard);
    }
  }

  Future<void> _handleAddSubBoardCard() async {
    final newBoardId = 'board_${const Uuid().v4()}';
    final repo = ref.read(boardRepositoryProvider);
    final now = DateTime.now();

    final meta = BoardMetadata(
      id: newBoardId,
      title: 'Sub-Board Baru',
      createdAt: now,
      updatedAt: now,
      cardCount: 0,
    );
    final canvas = CanvasData(
      boardId: newBoardId,
      cards: const [],
      arrows: const [],
      updatedAt: now,
    );
    await repo.saveBoard(metadata: meta, canvasData: canvas);

    final center = _getViewportCenterInCanvas();
    final newCard = SubBoardCard(
      id: const Uuid().v4(),
      x: center.dx - 140,
      y: center.dy - 90,
      width: 280,
      height: 180,
      zIndex: 100,
      targetBoardId: newBoardId,
      title: 'Sub-Board Baru',
      cardCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    ref.read(boardStateNotifierProvider.notifier).addCard(newCard);
  }

  void _handleOpenSubBoard(String childBoardId) {
    final currentTitle = ref.read(boardStateNotifierProvider).title;
    final updatedBreadcrumbs = [
      ...widget.breadcrumbs,
      BreadcrumbItem(boardId: widget.boardId, title: currentTitle),
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoardCanvasScreen(
          boardId: childBoardId,
          breadcrumbs: updatedBreadcrumbs,
        ),
      ),
    ).then((_) {
      ref.read(boardStateNotifierProvider.notifier).loadBoard(widget.boardId);
    });
  }

  void _handleBreadcrumbNavigate(BreadcrumbItem target) {
    if (target.boardId == widget.boardId) return;

    final targetIndex = widget.breadcrumbs.indexWhere((b) => b.boardId == target.boardId);
    if (targetIndex != -1) {
      final popsCount = widget.breadcrumbs.length - targetIndex;
      int count = 0;
      Navigator.of(context).popUntil((route) => count++ >= popsCount);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BoardCanvasScreen(
            boardId: target.boardId,
            breadcrumbs: const [],
          ),
        ),
      );
    }
  }

  Future<void> _renameCurrentBoard(String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: const Text('Ganti Nama Papan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama papan...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentTitle) {
      ref.read(boardStateNotifierProvider.notifier).updateTitle(result);
    }
  }

  void _handleFitToView() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? MediaQuery.of(context).size;
    final boardState = ref.read(boardStateNotifierProvider);
    final bounds = BoundingBoxCalculator.calculate(cards: boardState.cards);
    _canvasController.fitToView(
      contentBounds: bounds,
      viewportSize: size,
    );
  }

  Future<void> _handleClipboardPaste() async {
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final assetManager = ref.read(assetManagerProvider);
        final assetPath = await assetManager.saveAsset(
          boardId: widget.boardId,
          bytes: imageBytes,
          fileExtension: 'png',
        );

        final center = _getViewportCenterInCanvas();
        final newCard = ImageCard(
          id: const Uuid().v4(),
          x: center.dx - 160,
          y: center.dy - 120,
          width: 320,
          height: 240,
          zIndex: 100,
          assetUuid: assetPath,
          caption: 'Gambar dari Clipboard',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        ref.read(boardStateNotifierProvider.notifier).addCard(newCard);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gambar berhasil ditempel ke kanvas!'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Check text / URL from clipboard
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();
      if (text != null && text.isNotEmpty) {
        final center = _getViewportCenterInCanvas();
        final isUrl = (text.startsWith('http://') || text.startsWith('https://')) &&
            Uri.tryParse(text)?.hasScheme == true;

        if (isUrl) {
          final newCard = LinkCard(
            id: const Uuid().v4(),
            x: center.dx - 150,
            y: center.dy - 130,
            width: 300,
            height: 260,
            zIndex: 100,
            url: text,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          ref.read(boardStateNotifierProvider.notifier).addCard(newCard);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tautan web berhasil ditempel ke kanvas!'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          final newCard = NoteCard(
            id: const Uuid().v4(),
            x: center.dx - 140,
            y: center.dy - 110,
            width: 280,
            height: 220,
            zIndex: 100,
            title: 'Catatan Tempel',
            content: text,
            colorHex: '#FEF9C3',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          ref.read(boardStateNotifierProvider.notifier).addCard(newCard);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Teks berhasil ditempel ke kartu catatan!'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling clipboard paste: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final assetManager = ref.watch(assetManagerProvider);
    final boardState = ref.watch(boardStateNotifierProvider);
    final notifier = ref.read(boardStateNotifierProvider.notifier);

    final contentBounds = BoundingBoxCalculator.calculate(cards: boardState.cards);

    return CallbackShortcuts(
      bindings: {
        // Undo: Ctrl+Z / Cmd+Z
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (boardState.canUndo) notifier.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (boardState.canUndo) notifier.undo();
        },
        // Redo: Ctrl+Y / Cmd+Y
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (boardState.canRedo) notifier.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): () {
          if (boardState.canRedo) notifier.redo();
        },
        // Redo: Ctrl+Shift+Z / Cmd+Shift+Z
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          if (boardState.canRedo) notifier.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): () {
          if (boardState.canRedo) notifier.redo();
        },
        // Delete selected card or arrow
        const SingleActivator(LogicalKeyboardKey.delete): () {
          if (boardState.selectedCardId != null) {
            notifier.deleteCard(boardState.selectedCardId!);
          } else if (boardState.selectedArrowId != null) {
            notifier.deleteArrow(boardState.selectedArrowId!);
          }
        },
        const SingleActivator(LogicalKeyboardKey.backspace): () {
          if (boardState.selectedCardId != null) {
            notifier.deleteCard(boardState.selectedCardId!);
          } else if (boardState.selectedArrowId != null) {
            notifier.deleteArrow(boardState.selectedArrowId!);
          }
        },
        // Clipboard Paste: Ctrl+V / Cmd+V (US-005, FR-7)
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _handleClipboardPaste,
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): _handleClipboardPaste,
        // Duplicate selected card: Ctrl+D / Cmd+D
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): () {
          if (boardState.selectedCardId != null) {
            notifier.duplicateCard(boardState.selectedCardId!);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyD, meta: true): () {
          if (boardState.selectedCardId != null) {
            notifier.duplicateCard(boardState.selectedCardId!);
          }
        },
        // Deselect or cancel arrow mode: Escape
        const SingleActivator(LogicalKeyboardKey.escape): () {
          notifier.selectCard(null);
          notifier.selectArrow(null);
          if (boardState.isArrowMode) notifier.setArrowMode(false);
        },
        // Zoom In: Ctrl + '=' or Ctrl + '+'
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () => _canvasController.zoomIn(),
        const SingleActivator(LogicalKeyboardKey.equal, meta: true): () => _canvasController.zoomIn(),
        const SingleActivator(LogicalKeyboardKey.equal, control: true, shift: true): () => _canvasController.zoomIn(),
        const SingleActivator(LogicalKeyboardKey.equal, meta: true, shift: true): () => _canvasController.zoomIn(),
        // Zoom Out: Ctrl + '-'
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () => _canvasController.zoomOut(),
        const SingleActivator(LogicalKeyboardKey.minus, meta: true): () => _canvasController.zoomOut(),
        // Reset Zoom 100%: Ctrl + '0'
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () => _canvasController.resetZoom(),
        const SingleActivator(LogicalKeyboardKey.digit0, meta: true): () => _canvasController.resetZoom(),
        // Fit to View: Ctrl + '1'
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): _handleFitToView,
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): _handleFitToView,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              // Infinite Canvas Viewport hosting the cards & arrows
              CanvasViewport(
                controller: _canvasController,
                contentBounds: contentBounds,
                floatingToolbar: FloatingToolbar(
                  onAddNote: _handleAddNoteCard,
                  onAddImage: _handleAddImageCard,
                  onAddColor: _handleAddColorCard,
                  onAddLink: _handleAddLinkCard,
                  onAddSubBoard: _handleAddSubBoardCard,
                  isArrowMode: boardState.isArrowMode,
                  onToggleArrowMode: () {
                    notifier.setArrowMode(!boardState.isArrowMode);
                  },
                ),
                content: CanvasCardsLayer(
                  cards: boardState.cards,
                  arrows: boardState.arrows,
                  selectedCardId: boardState.selectedCardId,
                  selectedArrowId: boardState.selectedArrowId,
                  controller: _canvasController,
                  boardId: widget.boardId,
                  assetManager: assetManager,
                  onSelectCard: notifier.selectCard,
                  onMoveCard: (id, x, y) => notifier.moveCard(id, x, y, isFinal: false),
                  onMoveCardEnd: (id, fx, fy, sx, sy) =>
                      notifier.moveCard(id, fx, fy, isFinal: true, startX: sx, startY: sy),
                  onResizeCard: (id, w, h) => notifier.resizeCard(id, w, h, isFinal: false),
                  onResizeCardEnd: (id, fw, fh, sw, sh) =>
                      notifier.resizeCard(id, fw, fh, isFinal: true, startWidth: sw, startHeight: sh),
                  onDeleteCard: notifier.deleteCard,
                  onDuplicateCard: notifier.duplicateCard,
                  onBringToFront: notifier.bringToFront,
                  onUpdateCard: notifier.updateCard,
                  onAddArrow: notifier.addArrow,
                  onDeleteArrow: notifier.deleteArrow,
                  onSelectArrow: notifier.selectArrow,
                  onUpdateArrow: notifier.updateArrow,
                  onCardCreated: notifier.addCard,
                  onOpenSubBoard: _handleOpenSubBoard,
                ),
              ),

              // Top Header Bar with Project Title, Board Name, Undo/Redo, Autosave Indicator, Export, Theme
              Positioned(
                top: 16,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Group: Back to Gallery, Brand, Board Title
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Back to Gallery Button
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              tooltip: 'Kembali ke Galeri Papan',
                              onPressed: () async {
                                await notifier.flushAutosave();
                                if (context.mounted) {
                                  Navigator.of(context).maybePop();
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '🎨 LocalBoard',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 16,
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            const SizedBox(width: 8),
                            // Breadcrumbs if nested, or Clickable Board Title for inline renaming
                            if (widget.breadcrumbs.isNotEmpty) ...[
                              Flexible(
                                child: BreadcrumbBar(
                                  items: widget.breadcrumbs,
                                  onNavigate: _handleBreadcrumbNavigate,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                            Flexible(
                              child: InkWell(
                                onTap: () => _renameCurrentBoard(boardState.title),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          boardState.title,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 13,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right Group: Autosave indicator, Undo, Redo, Export PNG, Theme Switcher
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface)
                            .withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Autosave Status Pill (US-010 & STS-03)
                          _buildAutosaveBadge(boardState.autosaveStatus, isDark),

                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 16,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          const SizedBox(width: 4),

                          // Undo Button (STS-02 & FR-18)
                          IconButton(
                            icon: const Icon(Icons.undo_rounded, size: 18),
                            tooltip: 'Undo (Ctrl+Z)',
                            onPressed: boardState.canUndo ? () => notifier.undo() : null,
                          ),

                          // Redo Button (STS-02 & FR-18)
                          IconButton(
                            icon: const Icon(Icons.redo_rounded, size: 18),
                            tooltip: 'Redo (Ctrl+Y)',
                            onPressed: boardState.canRedo ? () => notifier.redo() : null,
                          ),

                          const SizedBox(width: 4),
                          Container(
                            width: 1,
                            height: 16,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          const SizedBox(width: 4),

                          // Export Menu (US-011, US-012, FR-14, FR-16, FR-17)
                          PopupMenuButton<String>(
                            tooltip: 'Ekspor Hasil Karya (PNG / PDF / .board)',
                            icon: const Icon(Icons.download_rounded, size: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                            onSelected: (val) async {
                              if (val == 'png') {
                                ExportPreviewDialog.show(
                                  context,
                                  cards: boardState.cards,
                                  arrows: boardState.arrows,
                                  boardTitle: boardState.title,
                                  isDark: isDark,
                                );
                              } else if (val == 'pdf') {
                                PdfExportDialog.show(
                                  context,
                                  boardTitle: boardState.title,
                                  boardId: widget.boardId,
                                  cards: boardState.cards,
                                  arrows: boardState.arrows,
                                  assetManager: assetManager,
                                  isDark: isDark,
                                );
                              } else if (val == 'board') {
                                try {
                                  final bundleService = ref.read(boardBundleServiceProvider);
                                  final path = await bundleService.exportBoardToFile(widget.boardId);
                                  if (path != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Papan berhasil diekspor ke: $path'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.accentSuccess,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal mengekspor papan: $e'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.accentDanger,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'png',
                                child: Row(
                                  children: [
                                    Icon(Icons.image_outlined, size: 16),
                                    SizedBox(width: 8),
                                    Text('Gambar Hi-Res (PNG)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'pdf',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text('Dokumen PDF (Poster / Katalog)'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'board',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive_outlined, size: 16, color: AppColors.accentPrimary),
                                    SizedBox(width: 8),
                                    Text('Paket Berkas Proyek (.board)'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Theme Mode Switcher
                          IconButton(
                            tooltip: isDark ? 'Beralih ke Studio Light' : 'Beralih ke Studio Dark',
                            icon: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              size: 18,
                            ),
                            onPressed: () {
                              ref.read(themeModeProvider.notifier).toggle();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutosaveBadge(AutosaveStatus status, bool isDark) {
    switch (status) {
      case AutosaveStatus.saving:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            SizedBox(width: 6),
            Text(
              'Menyimpan...',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        );
      case AutosaveStatus.saved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.accentSuccess,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Tersimpan di lokal',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        );
      case AutosaveStatus.error:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
            SizedBox(width: 4),
            Text(
              'Gagal menyimpan',
              style: TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ],
        );
      case AutosaveStatus.idle:
        return const SizedBox.shrink();
    }
  }
}
