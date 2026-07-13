import 'dart:convert';
import 'dart:typed_data';

/// Pure helpers for turning a gateway `qr_code_url` into renderable bytes and
/// deciding how to draw them. Kept free of Flutter/network so it is unit
/// testable; the widget handles the http(s) fetch and picks SVG vs bitmap.
abstract class QrPayload {
  /// Whether [value] is an http(s) URL the caller must fetch over the network.
  static bool isHttpUrl(String value) {
    final v = value.trim();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  /// Decodes an **inline** payload (not an http URL): a `data:` URI or a raw
  /// base64 string. Throws [FormatException] if it can't be decoded.
  static Uint8List decodeInline(String value) {
    final v = value.trim();

    // data:image/...;base64,xxxx (also handles percent-encoded data URIs)
    if (v.startsWith('data:')) {
      final data = Uri.parse(v).data;
      if (data == null) {
        throw const FormatException('Malformed data URI for QR');
      }
      return data.contentAsBytes();
    }

    // Raw base64 payload — strip whitespace/newlines, then normalize handles
    // padding and the url-safe alphabet.
    final compact = v.replaceAll(RegExp(r'\s'), '');
    if (compact.isEmpty) {
      throw const FormatException('Empty QR payload');
    }
    return base64Decode(base64.normalize(compact));
  }

  /// Sniffs whether [bytes] are an SVG document (XML text starting with
  /// `<?xml` or `<svg`) versus a raster image.
  static bool isSvg(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    final head = String.fromCharCodes(bytes.take(64)).trimLeft();
    return head.startsWith('<?xml') || head.startsWith('<svg');
  }
}
