import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/features/payment/presentation/screens/qr_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 1x1 transparent PNG.
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
  );
  const svgDoc =
      '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>';
  const svgXmlDoc =
      '<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg"/>';

  group('QrPayload.isHttpUrl', () {
    test('true for http and https (with surrounding whitespace)', () {
      expect(QrPayload.isHttpUrl('https://api.omise.co/x/qrcode.svg'), isTrue);
      expect(QrPayload.isHttpUrl('http://example.com/q.png'), isTrue);
      expect(QrPayload.isHttpUrl('  https://a.b/c  '), isTrue);
    });

    test('false for data URI and raw base64', () {
      expect(QrPayload.isHttpUrl('data:image/png;base64,AAAA'), isFalse);
      expect(QrPayload.isHttpUrl('iVBORw0KGgo='), isFalse);
      expect(QrPayload.isHttpUrl(''), isFalse);
    });
  });

  group('QrPayload.decodeInline', () {
    test('decodes a base64 data URI (png)', () {
      final uri = 'data:image/png;base64,${base64Encode(pngBytes)}';
      expect(QrPayload.decodeInline(uri), equals(pngBytes));
    });

    test('decodes a base64 data URI wrapping an SVG', () {
      final uri =
          'data:image/svg+xml;base64,${base64Encode(utf8.encode(svgDoc))}';
      final bytes = QrPayload.decodeInline(uri);
      expect(utf8.decode(bytes), svgDoc);
      expect(QrPayload.isSvg(bytes), isTrue); // round-trips through the sniffer
    });

    test('decodes a raw base64 payload', () {
      expect(QrPayload.decodeInline(base64Encode(pngBytes)), equals(pngBytes));
    });

    test('decodes raw base64 with embedded whitespace/newlines', () {
      final b64 = base64Encode(pngBytes);
      final wrapped = '${b64.substring(0, 8)}\n  ${b64.substring(8)}\n';
      expect(QrPayload.decodeInline(wrapped), equals(pngBytes));
    });

    test('decodes unpadded / url-safe base64 via normalize', () {
      final normal = base64Encode(pngBytes);
      final urlSafe = normal
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll('=', ''); // strip padding
      expect(QrPayload.decodeInline(urlSafe), equals(pngBytes));
    });

    test('throws FormatException on empty payload', () {
      expect(() => QrPayload.decodeInline('   '), throwsFormatException);
    });

    test('throws FormatException on non-base64 garbage', () {
      expect(() => QrPayload.decodeInline('!!!not base64!!!'),
          throwsFormatException);
    });
  });

  group('QrPayload.isSvg', () {
    test('true for <svg ...>', () {
      expect(QrPayload.isSvg(Uint8List.fromList(utf8.encode(svgDoc))), isTrue);
    });

    test('true for <?xml ...><svg>', () {
      expect(
        QrPayload.isSvg(Uint8List.fromList(utf8.encode(svgXmlDoc))),
        isTrue,
      );
    });

    test('true with leading whitespace before the tag', () {
      expect(
        QrPayload.isSvg(Uint8List.fromList(utf8.encode('  \n$svgDoc'))),
        isTrue,
      );
    });

    test('false for PNG magic bytes', () {
      expect(QrPayload.isSvg(pngBytes), isFalse);
    });

    test('false for empty bytes', () {
      expect(QrPayload.isSvg(Uint8List(0)), isFalse);
    });
  });
}
