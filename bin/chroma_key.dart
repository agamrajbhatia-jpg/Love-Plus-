import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final pets = ['capybara_front', 'bunny_front', 'puppy_front', 'kitty_front'];

  for (var pet in pets) {
    final file = File('assets/$pet.jpg');
    if (!file.existsSync()) continue;
    
    print('Processing $pet');
    final imageBytes = file.readAsBytesSync();
    final original = img.decodeImage(imageBytes)!;
    final rgbaImage = original.convert(numChannels: 4);
    
    for (int y = 0; y < rgbaImage.height; y++) {
      for (int x = 0; x < rgbaImage.width; x++) {
        final pixel = rgbaImage.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        // Chroma key for Green Screen
        // Green screen is typically highly saturated green
        if (g > 150 && r < 120 && b < 120) {
          pixel.a = 0;
        } else if (g > r * 1.2 && g > b * 1.2 && g > 80) {
          // Soft edge blending (anti-aliasing)
          final factor = (1.0 - ((g - r) / 255.0)).clamp(0.0, 1.0);
          pixel.a = (255 * factor * factor).toInt(); // Quadratic fade
        }
      }
    }

    final outBytes = img.encodePng(rgbaImage);
    File('assets/${pet}.png').writeAsBytesSync(outBytes);
  }
}
