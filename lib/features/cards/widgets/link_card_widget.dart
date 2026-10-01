import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../storage/data/asset_manager.dart';
import '../models/link_card.dart';
import '../services/opengraph_scraper.dart';

/// Visual web bookmark card with Open Graph metadata preview,
/// offline cover image caching, and external browser link opening (US-006 & FR-9).
class LinkCardWidget extends StatefulWidget {
  final LinkCard card;
  final String boardId;
  final AssetManager? assetManager;
  final bool isSelected;
  final ValueChanged<LinkCard>? onCardChanged;

  const LinkCardWidget({
    super.key,
    required this.card,
    required this.boardId,
    this.assetManager,
    this.isSelected = false,
    this.onCardChanged,
  });

  @override
  State<LinkCardWidget> createState() => _LinkCardWidgetState();
}

class _LinkCardWidgetState extends State<LinkCardWidget> {
  bool _isLoading = false;
  bool _isHovered = false;
  File? _resolvedCoverFile;

  @override
  void initState() {
    super.initState();
    _resolveCoverFile();
    // If URL is provided but title is empty, auto-fetch metadata
    if (widget.card.url.isNotEmpty &&
        widget.card.title.isEmpty &&
        widget.card.coverAssetUuid.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchMetadata(widget.card.url);
      });
    }
  }

  @override
  void didUpdateWidget(covariant LinkCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.coverAssetUuid != widget.card.coverAssetUuid) {
      _resolveCoverFile();
    }
  }

  Future<void> _resolveCoverFile() async {
    if (widget.card.coverAssetUuid.isEmpty || widget.assetManager == null) {
      if (mounted) setState(() => _resolvedCoverFile = null);
      return;
    }
    try {
      final file = await widget.assetManager!.getAssetFile(
        boardId: widget.boardId,
        relativePath: widget.card.coverAssetUuid,
      );
      if (mounted) {
        setState(() => _resolvedCoverFile = file);
      }
    } catch (_) {}
  }

  Future<void> _fetchMetadata(String url) async {
    if (url.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final scraper = OpenGraphScraper();
      final meta = await scraper.scrapeMetadata(
        rawUrl: url,
        boardId: widget.boardId,
        assetManager: widget.assetManager,
      );

      final updated = widget.card.copyWith(
        url: meta.url,
        title: meta.title,
        description: meta.description,
        siteName: meta.siteName,
        coverAssetUuid: meta.coverAssetUuid ?? '',
        coverImageUrl: meta.coverImageUrl ?? '',
        updatedAt: DateTime.now(),
      );

      widget.onCardChanged?.call(updated);
      await _resolveCoverFile();
    } catch (e) {
      debugPrint('Error fetching metadata: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openInBrowser() async {
    final raw = widget.card.url.trim();
    if (raw.isEmpty) return;

    final uri = OpenGraphScraper.sanitizeUrl(raw);
    if (uri != null) {
      try {
        final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka tautan: ${widget.card.url}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal meluncurkan browser: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _promptEditUrl() async {
    final textController = TextEditingController(text: widget.card.url);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: const Text('Masukkan Tautan Website',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tempel URL artikel, Pinterest, ArtStation, YouTube, atau referensi visual:',
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
            child: const Text('Simpan & Muat Pratinjau'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != widget.card.url) {
      widget.onCardChanged?.call(widget.card.copyWith(
        url: result,
        title: '',
        description: '',
        coverAssetUuid: '',
        coverImageUrl: '',
        updatedAt: DateTime.now(),
      ));
      await _fetchMetadata(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onDoubleTap: _openInBrowser,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Cover Thumbnail Area
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCoverImage(isDark),

                    // Loading indicator
                    if (_isLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Quick Action Buttons on Hover or Selection
                    if (_isHovered || widget.isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QuickActionBtn(
                              icon: Icons.refresh_rounded,
                              tooltip: 'Muat Ulang Pratinjau',
                              onPressed: () => _fetchMetadata(widget.card.url),
                            ),
                            const SizedBox(width: 4),
                            _QuickActionBtn(
                              icon: Icons.edit_rounded,
                              tooltip: 'Ubah URL',
                              onPressed: _promptEditUrl,
                            ),
                            const SizedBox(width: 4),
                            _QuickActionBtn(
                              icon: Icons.open_in_new_rounded,
                              tooltip: 'Buka di Browser',
                              onPressed: _openInBrowser,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Details Area (Domain, Title, Description)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Domain / Site Name Badge
                          Row(
                            children: [
                              Icon(
                                Icons.public_rounded,
                                size: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.card.siteName.isNotEmpty
                                      ? widget.card.siteName
                                      : (widget.card.url.isNotEmpty ? widget.card.url : 'Belum ada tautan'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Title
                          Text(
                            widget.card.title.isNotEmpty
                                ? widget.card.title
                                : (widget.card.url.isNotEmpty
                                    ? widget.card.url
                                    : 'Klik ganda untuk memasukkan URL'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),

                      // Description / Snippet
                      if (widget.card.description.isNotEmpty)
                        Text(
                          widget.card.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary.withValues(alpha: 0.8)
                                : AppColors.lightTextSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(bool isDark) {
    // 1. Check local cached asset file first (offline-first guarantee)
    if (_resolvedCoverFile != null && _resolvedCoverFile!.existsSync()) {
      return Image.file(
        _resolvedCoverFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
      );
    }

    // 2. Check fallback network URL if local cache not yet generated
    if (widget.card.coverImageUrl.isNotEmpty) {
      return Image.network(
        widget.card.coverImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
      );
    }

    // 3. Fallback placeholder
    return _buildPlaceholder(isDark);
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_rounded,
              size: 32,
              color: isDark
                  ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                  : AppColors.lightTextSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              widget.card.url.isNotEmpty ? 'Pratinjau Web' : 'Tambah Tautan',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
                    : AppColors.lightTextSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _QuickActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
