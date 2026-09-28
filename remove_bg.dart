import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = 'assets/logo.jpg';
  final outputPath = 'assets/logo.png';
  print('Loading image from ');
  final bytes = File(inputPath).readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;
  final int width = image.width;
  final int height = image.height;
  final double centerX = width / 2;
  final double centerY = height / 2;
  final double radius = (width / 2) * 0.98;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final dx = x - centerX;
      final dy = y - centerY;
      final distance = dx * dx + dy * dy;
      if (distance > radius * radius) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  File(outputPath).writeAsBytesSync(img.encodePng(image));
  print('Done!');
}
