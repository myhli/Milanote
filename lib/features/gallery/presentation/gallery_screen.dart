import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localboard/app/app.dart';
import 'package:localboard/core/theme/app_colors.dart';
import 'package:localboard/features/storage/domain/board_metadata.dart';
import 'package:localboard/features/storage/domain/canvas_data.dart';
import 'package:localboard/features/storage/storage_providers.dart';
import 'package:localboard/features/templates/domain/starter_templates.dart';
import 'package:uuid/uuid.dart';
import 'widgets/board_grid_card.dart';
import 'widgets/template_selection_modal.dart';

/// Main Gallery Dashboard displaying all local project boards with instant search,
/// template initialization, and board management (rename, duplicate, delete).
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BoardMetadata> _boards = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBoards() async {
    setState(() => _isLoading = true);
    final repo = ref.read(boardRepositoryProvider);
    try {
      final list = await repo.getBoards();
      if (mounted) {
        setState(() {
          _boards = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<BoardMetadata> get _filteredBoards {
    if (_searchQuery.trim().isEmpty) return _boards;
    final q = _searchQuery.toLowerCase().trim();
    return _boards.where((b) => b.title.toLowerCase().contains(q)).toList();
  }

  void _openBoard(String boardId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoardCanvasScreen(boardId: boardId),
      ),
    ).then((_) => _loadBoards());
  }

  Future<void> _createNewBoard() async {
    final newId = 'board_${const Uuid().v4()}';
    final repo = ref.read(boardRepositoryProvider);
    final now = DateTime.now();

    final meta = BoardMetadata(
      id: newId,
      title: 'Papan Tanpa Judul',
      createdAt: now,
      updatedAt: now,
      cardCount: 0,
    );

    final canvas = CanvasData(
      boardId: newId,
      cards: const [],
      arrows: const [],
      updatedAt: now,
    );

    await repo.saveBoard(metadata: meta, canvasData: canvas);
    if (!mounted) return;
    _openBoard(newId);
  }

  Future<void> _createBoardFromTemplate(ArtisticTemplate template) async {
    final newId = 'board_${const Uuid().v4()}';
    final repo = ref.read(boardRepositoryProvider);
    final now = DateTime.now();
    final (cards, arrows) = template.builder(newId);

    final meta = BoardMetadata(
      id: newId,
      title: template.name,
      createdAt: now,
      updatedAt: now,
      cardCount: cards.length,
    );

    final canvas = CanvasData(
      boardId: newId,
      cards: cards.map((c) => c.toJson()).toList(),
      arrows: arrows.map((a) => a.toJson()).toList(),
      updatedAt: now,
    );

    await repo.saveBoard(metadata: meta, canvasData: canvas);
    if (!mounted) return;
    _openBoard(newId);
  }

  Future<void> _renameBoard(BoardMetadata board) async {
    final controller = TextEditingController(text: board.title);
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
            hintText: 'Masukkan nama papan...',
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

    if (result != null && result.isNotEmpty && result != board.title) {
      final repo = ref.read(boardRepositoryProvider);
      final updated = board.copyWith(title: result, updatedAt: DateTime.now());
      await repo.updateMetadata(updated);
      _loadBoards();
    }
  }

  Future<void> _duplicateBoard(BoardMetadata board) async {
    final repo = ref.read(boardRepositoryProvider);
    try {
      await repo.duplicateBoard(
        sourceBoardId: board.id,
        newTitle: '${board.title} (Salinan)',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Papan "${board.title}" berhasil diduplikasi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBoards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menduplikasi papan: $e')),
        );
      }
    }
  }

  Future<void> _deleteBoard(BoardMetadata board) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: const Text('Hapus Papan Proyek?'),
        content: Text(
          'Papan "${board.title}" beserta seluruh gambar dan catatannya akan dihapus secara permanen dari perangkat lokal ini.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus Papan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(boardRepositoryProvider);
      await repo.deleteBoard(board.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Papan "${board.title}" telah dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBoards();
      }
    }
  }

  Future<void> _exportBoard(BoardMetadata board) async {
    try {
      final bundleService = ref.read(boardBundleServiceProvider);
      final path = await bundleService.exportBoardToFile(board.id);
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Papan "${board.title}" berhasil diekspor ke: $path'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accentSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  Future<void> _importBoard() async {
    try {
      final bundleService = ref.read(boardBundleServiceProvider);
      final imported = await bundleService.pickAndImportBoard();
      if (imported != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Papan "${imported.title}" berhasil diimpor!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accentSuccess,
          ),
        );
        _loadBoards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengimpor papan: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final boards = _filteredBoards;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvasBackground : AppColors.lightCanvasBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Studio Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 950;
                  final isNarrow = constraints.maxWidth < 650;

                  return Row(
                    children: [
                      // App Brand & Logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.brush_rounded,
                              color: AppColors.accentPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'LocalBoard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (!isNarrow)
                                Text(
                                  'Galeri Papan Studio',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 40,
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: isNarrow ? 'Cari...' : 'Cari judul papan...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.accentPrimary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Theme Toggle Button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          tooltip: isDark ? 'Beralih ke Studio Light' : 'Beralih ke Studio Dark',
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).toggle();
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Template Selection Button
                      if (isCompact)
                        IconButton(
                          tooltip: 'Gunakan Template',
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          onPressed: () {
                            TemplateSelectionModal.show(
                              context,
                              onSelectTemplate: _createBoardFromTemplate,
                            );
                          },
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text('Gunakan Template',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          onPressed: () {
                            TemplateSelectionModal.show(
                              context,
                              onSelectTemplate: _createBoardFromTemplate,
                            );
                          },
                        ),

                      const SizedBox(width: 8),

                      // Import .board Button (US-011)
                      if (isCompact)
                        IconButton(
                          tooltip: 'Impor Berkas .board',
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          onPressed: _importBoard,
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          icon: const Icon(Icons.file_upload_outlined, size: 16),
                          label: const Text('Impor .board',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          onPressed: _importBoard,
                        ),

                      const SizedBox(width: 8),

                      // Create New Board Button
                      if (isCompact)
                        IconButton.filled(
                          tooltip: 'Buat Papan Baru',
                          style: IconButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          onPressed: _createNewBoard,
                        )
                      else
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Buat Papan Baru',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          onPressed: _createNewBoard,
                        ),
                    ],
                  );
                },
              ),
            ),

            // Content Area (Grid / Empty State / Loading)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : boards.isEmpty
                      ? _buildEmptyState(isDark)
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              int cols = 1;
                              if (constraints.maxWidth >= 1300) {
                                cols = 4;
                              } else if (constraints.maxWidth >= 900) {
                                cols = 3;
                              } else if (constraints.maxWidth >= 600) {
                                cols = 2;
                              }

                              return GridView.builder(
                                itemCount: boards.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1.25,
                                ),
                                itemBuilder: (context, index) {
                                  final board = boards[index];
                                  return BoardGridCard(
                                    metadata: board,
                                    onTap: () => _openBoard(board.id),
                                    onRename: () => _renameBoard(board),
                                    onDuplicate: () => _duplicateBoard(board),
                                    onDelete: () => _deleteBoard(board),
                                    onExport: () => _exportBoard(board),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearching ? Icons.search_off_rounded : Icons.space_dashboard_rounded,
                  size: 36,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSearching ? 'Tidak Ada Papan Ditemukan' : 'Belum Ada Papan Proyek',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Tidak ada papan proyek dengan nama "$_searchQuery". Coba kata kunci lain.'
                    : 'Mulai perjalanan eksplorasi seni Anda dengan membuat kanvas baru atau memilih template terstruktur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              if (!isSearching)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('Lihat Template'),
                      onPressed: () {
                        TemplateSelectionModal.show(
                          context,
                          onSelectTemplate: _createBoardFromTemplate,
                        );
                      },
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Buat Papan Baru'),
                      onPressed: _createNewBoard,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
