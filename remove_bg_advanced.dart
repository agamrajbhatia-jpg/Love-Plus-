import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    print('assets directory not found');
    return;
  }

  final pets = ['capybara_front', 'bunny_front', 'puppy_front', 'kitty_front'];

  for (var pet in pets) {
    final file = File('assets/$pet.jpg');
    if (!file.existsSync()) {
      print('File not found: ${file.path}');
      continue;
    }

    print('Processing $pet...');
    final imageBytes = file.readAsBytesSync();
    final original = img.decodeImage(imageBytes)!;
    
    // Resize down slightly if it's huge, but keep original for now
    final width = original.width;
    final height = original.height;
    
    // 1. Create a smoothed version to eliminate JPG noise and snowy static
    final smoothed = img.gaussianBlur(original, radius: 4);
    
    // 2. Flood fill mask on the smoothed image
    final mask = List.generate(width * height, (_) => false);
    final queue = <Point>[];
    
    // Add all border pixels to queue
    for (int x = 0; x < width; x++) {
      queue.add(Point(x, 0));
      queue.add(Point(x, height - 1));
    }
    for (int y = 0; y < height; y++) {
      queue.add(Point(0, y));
      queue.add(Point(width - 1, y));
    }
    
    // We treat anything that is light/low saturation as background
    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      final x = p.x;
      final y = p.y;
      
      final idx = y * width + x;
      if (mask[idx]) continue;
      
      final pixel = smoothed.getPixel(x, y);
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;
      
      // Calculate luminance and saturation
      final maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
      final minC = [r, g, b].reduce((a, b) => a < b ? a : b);
      
      final luma = (0.299 * r + 0.587 * g + 0.114 * b);
      final sat = maxC == 0 ? 0 : (maxC - minC) / maxC * 100;
      
      // If it's bright enough AND low saturation (gray/white/noisy white)
      // Or if it's very bright
      bool isBg = false;
      if (luma > 200 && sat < 30) isBg = true;
      if (luma > 230) isBg = true;
      
      // For the snowy pedestal at the bottom, which is pure white
      if (y > height * 0.75 && luma > 180 && sat < 20) isBg = true;

      if (isBg) {
        mask[idx] = true;
        if (x > 0) queue.add(Point(x - 1, y));
        if (x < width - 1) queue.add(Point(x + 1, y));
        if (y > 0) queue.add(Point(x, y - 1));
        if (y < height - 1) queue.add(Point(x, y + 1));
      }
    }

    // 3. Apply mask to original image with alpha feathering
    final rgbaImage = original.convert(numChannels: 4);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        if (mask[idx]) {
          rgbaImage.setPixelRgba(x, y, 0, 0, 0, 0); // Transparent
        }
      }
    }

    // 4. Feathering (simple box blur on alpha channel only to soften edges)
    final feathered = rgbaImage.clone();
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        if (!mask[y * width + x]) {
          int alphaSum = 0;
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              alphaSum += rgbaImage.getPixel(x + dx, y + dy).a.toInt();
            }
          }
          final avgAlpha = alphaSum ~/ 9;
          final p = feathered.getPixel(x, y);
          feathered.setPixelRgba(p.r.toInt(), p.g.toInt(), p.b.toInt(), avgAlpha);
        }
      }
    }

    final outBytes = img.encodePng(feathered);
    File('assets/${pet}.png').writeAsBytesSync(outBytes);
    print('Saved ${pet}.png');
  }
}

class Point {
  final int x, y;
  Point(this.x, this.y);
}
