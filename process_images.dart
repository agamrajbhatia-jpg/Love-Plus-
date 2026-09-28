import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() async {
  final assets = ['capybara_front', 'bunny_front', 'puppy_front', 'kitty_front'];
  final dir = Directory('C:/Users/agamr/.gemini/antigravity/scratch/couple_app/assets');

  for (final asset in assets) {
    File file = File('${dir.path}/$asset.png');
    if (!file.existsSync()) {
      file = File('${dir.path}/$asset.jpg');
    }
    if (!file.existsSync()) {
      print('Not found: $asset');
      continue;
    }

    print('Processing $asset...');
    final imageBytes = file.readAsBytesSync();
    final image = img.decodeImage(imageBytes);

    if (image == null) continue;

    // We'll create a new image with alpha channel
    final out = img.Image(width: image.width, height: image.height, numChannels: 4);

    // Green screen color target
    final targetR = 0;
    final targetG = 255;
    final targetB = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        // Calculate distance in RGB space to pure green
        double dist = sqrt(pow(r - targetR, 2) + pow(g - targetG, 2) + pow(b - targetB, 2));

        if (dist < 180) { // Very close to green
          // Smooth alpha transition
          int a = 0;
          if (dist > 120) {
            a = ((dist - 120) / 60 * 255).toInt();
          }
          // Remove the green spill by tinting it towards gray/brown (average pet color)
          if (a > 0) {
            // Desaturate the green spill slightly
            int gray = ((r + g + b) / 3).toInt();
            g = (g * 0.5 + gray * 0.5).toInt();
          }
          out.setPixel(x, y, img.ColorRgba8(r, g, b, a));
        } else {
          out.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
        }
      }
    }

    // Save as PNG
    final outBytes = img.encodePng(out);
    File('${dir.path}/$asset.png').writeAsBytesSync(outBytes);
    // If it was a jpg, delete the jpg to avoid confusion
    if (file.path.endsWith('.jpg')) {
      file.deleteSync();
    }
    print('Saved ${dir.path}/$asset.png');
  }
}
