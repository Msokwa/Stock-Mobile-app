import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final inPath = 'assets/logo/stockscope.png';
  final outPath = 'assets/logo/stockscope_rounded.png';
  const int size = 1024;
  const int radius = 180; // adjust curvature (higher => more rounded)

  if (!File(inPath).existsSync()) {
    stderr.writeln('Input file not found: $inPath');
    exit(2);
  }

  final bytes = File(inPath).readAsBytesSync();
  final src = img.decodeImage(bytes);
  if (src == null) {
    stderr.writeln('Unable to decode image: $inPath');
    exit(3);
  }

  // Resize to fit square, preserving aspect ratio
  img.Image resized;
  if (src.width >= src.height) {
    resized = img.copyResize(src, width: size);
  } else {
    resized = img.copyResize(src, height: size);
  }

  // Center-crop to square if needed
  img.Image dst;
  if (resized.width == size && resized.height == size) {
    dst = img.Image.from(resized);
  } else {
    final x = max(0, (resized.width - size) ~/ 2);
    final y = max(0, (resized.height - size) ~/ 2);
    dst = img.copyCrop(
      resized,
      x: x,
      y: y,
      width: min(size, resized.width),
      height: min(size, resized.height),
    );
    if (dst.width != size || dst.height != size) {
      dst = img.copyResize(dst, width: size, height: size);
    }
  }

  // Apply rounded-corner alpha mask
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      var inside = true;

      // Top-left
      if (x < radius && y < radius) {
        final dx = (radius - x).toDouble();
        final dy = (radius - y).toDouble();
        if (dx * dx + dy * dy > radius * radius) inside = false;
      }
      // Top-right
      else if (x >= size - radius && y < radius) {
        final dx = (x - (size - radius - 1)).toDouble();
        final dy = (radius - y).toDouble();
        if (dx * dx + dy * dy > radius * radius) inside = false;
      }
      // Bottom-left
      else if (x < radius && y >= size - radius) {
        final dx = (radius - x).toDouble();
        final dy = (y - (size - radius - 1)).toDouble();
        if (dx * dx + dy * dy > radius * radius) inside = false;
      }
      // Bottom-right
      else if (x >= size - radius && y >= size - radius) {
        final dx = (x - (size - radius - 1)).toDouble();
        final dy = (y - (size - radius - 1)).toDouble();
        if (dx * dx + dy * dy > radius * radius) inside = false;
      }

      if (!inside) {
        final p = dst.getPixel(x, y);
        final r = p.r;
        final g = p.g;
        final b = p.b;
        dst.setPixelRgba(x, y, r, g, b, 0);
      }
    }
  }

  final out = img.encodePng(dst);
  File(outPath).writeAsBytesSync(out);
  stdout.writeln('Wrote $outPath');
}
