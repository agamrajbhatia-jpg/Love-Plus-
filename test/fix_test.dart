import 'dart:io';

void main() {
  final files = [
    "lib/screens/games/would_you_rather_screen.dart",
    "lib/screens/games/how_well_do_you_know_me_screen.dart",
    "lib/screens/games/scenario_scale_screen.dart",
    "lib/screens/games/how_mad_screen.dart",
    "lib/screens/games/expose_us_screen.dart",
    "lib/screens/games/ranking_date_ideas_screen.dart"
  ];

  for (final filename in files) {
    final file = File(filename);
    String content = file.readAsStringSync();
    
    // Find the real colors string from earlier in the file (in the DynamicBackground body)
    final realColorRegex = RegExp(r'colors:\s*(const \[Color\([^)]+\),\s*Color\([^)]+\)\])');
    final allMatches = realColorRegex.allMatches(content);
    if (allMatches.length > 0) {
        // The last match is probably the correct one
        final realColors = allMatches.last.group(1);
        content = content.replaceAll(r'colors: $colorsStr,', 'colors: \$realColors,');
        content = content.replaceAll(r'$realColors', realColors!);
        file.writeAsStringSync(content);
        print("Fixed " + filename);
    }
  }
}
