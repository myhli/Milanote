import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/cards/services/opengraph_scraper.dart';

void main() {
  group('OpenGraphScraper Tests (ADV-01)', () {
    test('sanitizeUrl handles valid URLs and prepends https:// when missing', () {
      final u1 = OpenGraphScraper.sanitizeUrl('https://artstation.com/artwork/123');
      expect(u1, isNotNull);
      expect(u1?.scheme, 'https');
      expect(u1?.host, 'artstation.com');

      final u2 = OpenGraphScraper.sanitizeUrl('pinterest.com/pin/456');
      expect(u2, isNotNull);
      expect(u2?.scheme, 'https');
      expect(u2?.host, 'pinterest.com');

      final u3 = OpenGraphScraper.sanitizeUrl('   http://example.org/test   ');
      expect(u3, isNotNull);
      expect(u3?.scheme, 'http');

      expect(OpenGraphScraper.sanitizeUrl(''), isNull);
      expect(OpenGraphScraper.sanitizeUrl('   '), isNull);
    });

    test('parseHtmlMetadata extracts og:title, og:description, og:image, and og:site_name', () {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="Konsep Seni Karakter Fantasi &amp; Senjata" />
  <meta property="og:description" content="Koleksi lukisan digital dan palet warna karakter fantasi." />
  <meta property="og:image" content="https://artstation.com/images/concept.jpg" />
  <meta property="og:site_name" content="ArtStation Studio" />
</head>
<body><h1>Hello World</h1></body>
</html>
''';

      final meta = OpenGraphScraper.parseHtmlMetadata(
        html,
        Uri.parse('https://artstation.com/artwork/123'),
      );

      expect(meta.title, 'Konsep Seni Karakter Fantasi & Senjata');
      expect(meta.description, 'Koleksi lukisan digital dan palet warna karakter fantasi.');
      expect(meta.coverImageUrl, 'https://artstation.com/images/concept.jpg');
      expect(meta.siteName, 'ArtStation Studio');
    });

    test('parseHtmlMetadata falls back to title tag and meta description if og tags missing', () {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <title>Inspirasi Desain Grafis &quot;Modern&quot;</title>
  <meta name="description" content="Portal kurasi seni dan referensi visual." />
</head>
<body></body>
</html>
''';

      final meta = OpenGraphScraper.parseHtmlMetadata(
        html,
        Uri.parse('https://designportal.id/artikel/1'),
      );

      expect(meta.title, 'Inspirasi Desain Grafis "Modern"');
      expect(meta.description, 'Portal kurasi seni dan referensi visual.');
      expect(meta.siteName, 'designportal.id');
      expect(meta.coverImageUrl, isNull);
    });

    test('parseHtmlMetadata resolves relative image URLs to base URI', () {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="Studi Proporsi Anatomi" />
  <meta property="og:image" content="/assets/covers/anatomy.png" />
</head>
</html>
''';

      final meta = OpenGraphScraper.parseHtmlMetadata(
        html,
        Uri.parse('https://anatomyforartists.com/tutorials/proportions'),
      );

      expect(meta.title, 'Studi Proporsi Anatomi');
      expect(meta.coverImageUrl, 'https://anatomyforartists.com/assets/covers/anatomy.png');
    });
  });
}
