import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Longest side a chat photo is scaled down to before upload.
const int kChatImageMaxSide = 1600;

/// The `chat` media category's cap (2MB).
const int kChatImageMaxBytes = 2 * 1024 * 1024;

/// Turns a picked photo into what the chat uploads: the EXIF rotation applied
/// to the pixels, the longest side scaled to [kChatImageMaxSide], re-encoded
/// as JPEG (quality 80, lowered until it fits [kChatImageMaxBytes]) with no
/// EXIF at all — phone photos carry the GPS position they were taken at.
///
/// Throws a [FormatException] when [raw] isn't a decodable image.
Uint8List prepareChatImage(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) throw const FormatException('Not an image');

  var image = img.bakeOrientation(decoded);
  final longest = math.max(image.width, image.height);
  if (longest > kChatImageMaxSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: kChatImageMaxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: kChatImageMaxSide,
            interpolation: img.Interpolation.average,
          );
  }
  // JPEG has no alpha: put a transparent PNG / screenshot on white.
  if (image.hasAlpha) {
    final canvas = img.Image(width: image.width, height: image.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(canvas, image);
  }
  image.exif = img.ExifData();

  for (var quality = 80; ; quality -= 10) {
    final jpeg = img.encodeJpg(image, quality: quality);
    if (jpeg.length <= kChatImageMaxBytes || quality <= 40) return jpeg;
  }
}

/// [prepareChatImage] off the UI isolate.
Future<Uint8List> prepareChatImageInBackground(Uint8List raw) =>
    compute(prepareChatImage, raw);
