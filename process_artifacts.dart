import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() async {
  final files = {
    'capybara': 'capybara_greenscreen_1785484038497.jpg',
    'bunny': 'bunny_greenscreen_1785484050996.jpg',
    'puppy': 'puppy_greenscreen_1785484076346.jpg',
    'kitty': 'kitty_greenscreen_1785484089027.jpg'
  };

  final artifactDir = 'C:/Users/agamr/.gemini/antigravity/brain/4c4cd6f2-40fe-4ede-9dcd-80ee36325579';
  final outDir = 'C:/Users/agamr/.gemini/antigravity/scratch/couple_app/assets';

  for (final entry in files.entries) {
    final pet = entry.key;
    final filename = entry.value;

    final file = File('$artifactDir/$filename');
    if (!file.existsSync()) {
      print('Not found: $filename');
      continue;
    }

    print('Processing $pet...');
    final imageBytes = file.readAsBytesSync();
    final image = img.decodeImage(imageBytes);

    if (image == null) continue;

    final out = img.Image(width: image.width, height: image.height, numChannels: 4);

    final targetR = 0;
    final targetG = 255;
    final targetB = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        double dist = sqrt(pow(r - targetR, 2) + pow(g - targetG, 2) + pow(b - targetB, 2));

        if (dist < 180) { // Green screen zone
          int a = 0;
          if (dist > 110) {
             // Smoother falloff
             a = ((dist - 110) / 70 * 255).toInt();
          }
          if (a > 0) {
            int gray = ((r + g + b) / 3).toInt();
            g = (g * 0.4 + gray * 0.6).toInt();
          }
          out.setPixelRgba(x, y, r, g, b, a); // Use setPixelRgba for explicit 4-channel support!
        } else {
          out.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }

    // Save as v2.png
    final outBytes = img.encodePng(out);
    File('$outDir/${pet}_front_v2.png').writeAsBytesSync(outBytes);
    print('Saved $outDir/${pet}_front_v2.png');
  }
}
