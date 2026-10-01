import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../storage/data/asset_manager.dart';

/// Metadata extracted from a web link for visual bookmarking.
@immutable
class LinkMetadata {
  final String url;
  final String title;
  final String description;
  final String? coverImageUrl;
  final String? coverAssetUuid;
  final String siteName;

  const LinkMetadata({
    required this.url,
    required this.title,
    this.description = '',
    this.coverImageUrl,
    this.coverAssetUuid,
    required this.siteName,
  });

  LinkMetadata copyWith({
    String? url,
    String? title,
    String? description,
    String? coverImageUrl,
    String? coverAssetUuid,
    String? siteName,
  }) {
    return LinkMetadata(
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverAssetUuid: coverAssetUuid ?? this.coverAssetUuid,
      siteName: siteName ?? this.siteName,
    );
  }
}

/// Service for extracting Open Graph and HTML metadata from web links
/// and caching cover thumbnails locally for 100% offline availability (US-006 & FR-9).
class OpenGraphScraper {
  final http.Client _client;

  OpenGraphScraper({http.Client? client}) : _client = client ?? http.Client();

  /// Standard browser User-Agent to avoid scraping blocks.
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
  };

  /// Sanitizes input URL string ensuring valid schema.
  static Uri? sanitizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    String formatted = trimmed;
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }

    try {
      final uri = Uri.parse(formatted);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        return uri;
      }
    } catch (_) {}
    return null;
  }

  /// Scrapes Open Graph metadata from given URL and caches thumbnail image locally.
  Future<LinkMetadata> scrapeMetadata({
    required String rawUrl,
    required String boardId,
    AssetManager? assetManager,
  }) async {
    final uri = sanitizeUrl(rawUrl);
    if (uri == null) {
      return LinkMetadata(
        url: rawUrl,
        title: rawUrl,
        description: 'Tautan tidak valid',
        siteName: '',
      );
    }

    final siteName = uri.host.replaceFirst(RegExp(r'^www\.'), '');

    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final parsed = parseHtmlMetadata(body, uri);

        String? localAssetPath;
        if (parsed.coverImageUrl != null && assetManager != null) {
          localAssetPath = await _downloadAndCacheCover(
            imageUrl: parsed.coverImageUrl!,
            boardId: boardId,
            assetManager: assetManager,
          );
        }

        return parsed.copyWith(
          url: uri.toString(),
          coverAssetUuid: localAssetPath,
          siteName: parsed.siteName.isNotEmpty ? parsed.siteName : siteName,
        );
      }
    } catch (e) {
      debugPrint('OpenGraphScraper error for $rawUrl: $e');
    }

    // Fallback when offline or request failed
    return LinkMetadata(
      url: uri.toString(),
      title: siteName.isNotEmpty ? siteName : uri.toString(),
      description: 'Pratinjau belum dimuat (offline atau tautan privat)',
      siteName: siteName,
    );
  }

  /// Pure parser extracting OpenGraph and fallback tags from raw HTML content.
  static LinkMetadata parseHtmlMetadata(String html, Uri baseUri) {
    String? title;
    String? description;
    String? imageUrl;
    String? siteName;

    // 1. Open Graph & Twitter meta tags
    final metaRegex = RegExp(
      r'''<meta\s+[^>]*?(?:property|name)=["']([^"']+)["'][^>]*?content=["']([^"']*)["'][^>]*?>''',
      caseSensitive: false,
    );

    // Also support reversed attribute order: content="..." property="..."
    final metaRegexAlt = RegExp(
      r'''<meta\s+[^>]*?content=["']([^"']*)["'][^>]*?(?:property|name)=["']([^"']+)["'][^>]*?>''',
      caseSensitive: false,
    );

    for (final match in metaRegex.allMatches(html)) {
      final key = match.group(1)?.toLowerCase() ?? '';
      final val = _unescapeHtml(match.group(2)?.trim() ?? '');
      _assignTag(key, val, (t) => title ??= t, (d) => description ??= d,
          (img) => imageUrl ??= img, (sn) => siteName ??= sn);
    }

    for (final match in metaRegexAlt.allMatches(html)) {
      final key = match.group(2)?.toLowerCase() ?? '';
      final val = _unescapeHtml(match.group(1)?.trim() ?? '');
      _assignTag(key, val, (t) => title ??= t, (d) => description ??= d,
          (img) => imageUrl ??= img, (sn) => siteName ??= sn);
    }

    // 2. Fallback to <title> tag if no og:title
    if (title == null || title!.isEmpty) {
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false)
          .firstMatch(html);
      if (titleMatch != null) {
        title = _unescapeHtml(titleMatch.group(1)?.trim() ?? '');
      }
    }

    // 3. Fallback siteName to baseUri host
    siteName ??= baseUri.host.replaceFirst(RegExp(r'^www\.'), '');
    title ??= siteName;

    // 4. Resolve relative image URL against baseUri
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      try {
        final parsedImgUri = Uri.parse(imageUrl!);
        if (!parsedImgUri.hasScheme) {
          imageUrl = baseUri.resolveUri(parsedImgUri).toString();
        }
      } catch (_) {}
    }

    return LinkMetadata(
      url: baseUri.toString(),
      title: title!,
      description: description ?? '',
      coverImageUrl: (imageUrl != null && imageUrl!.isNotEmpty) ? imageUrl : null,
      siteName: siteName ?? '',
    );
  }

  static void _assignTag(
    String key,
    String val,
    void Function(String) setTitle,
    void Function(String) setDesc,
    void Function(String) setImage,
    void Function(String) setSiteName,
  ) {
    if (val.isEmpty) return;
    if (key == 'og:title' || key == 'twitter:title') {
      setTitle(val);
    } else if (key == 'og:description' ||
        key == 'twitter:description' ||
        key == 'description') {
      setDesc(val);
    } else if (key == 'og:image' || key == 'twitter:image') {
      setImage(val);
    } else if (key == 'og:site_name') {
      setSiteName(val);
    }
  }

  /// Downloads cover image bytes and saves to asset directory for offline viewing.
  Future<String?> _downloadAndCacheCover({
    required String imageUrl,
    required String boardId,
    required AssetManager assetManager,
  }) async {
    try {
      final uri = Uri.parse(imageUrl);
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Detect extension from image URL or default to png
        String ext = 'png';
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final lastSeg = pathSegments.last.toLowerCase();
          if (lastSeg.endsWith('.jpg') || lastSeg.endsWith('.jpeg')) ext = 'jpg';
          if (lastSeg.endsWith('.webp')) ext = 'webp';
          if (lastSeg.endsWith('.png')) ext = 'png';
        }

        final assetPath = await assetManager.saveAsset(
          boardId: boardId,
          bytes: response.bodyBytes,
          fileExtension: ext,
        );
        return assetPath;
      }
    } catch (e) {
      debugPrint('Failed to download cover image: $e');
    }
    return null;
  }

  static String _unescapeHtml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  void dispose() {
    _client.close();
  }
}
