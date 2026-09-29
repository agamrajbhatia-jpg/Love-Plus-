import 'dart:io';
import 'dart:convert';

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
    String content = file.readAsStringSync(encoding: utf8);
    
    // Fix literal \n
    content = content.replaceAll(r'setState(() {\n          _isLocked = true;\n          _lockTitle = "Daily Limit Reached";\n          _lockSubtitle = "Come back tomorrow! â ³";', 
    '''setState(() {
          _isLocked = true;
          _lockTitle = "Daily Limit Reached";
          _lockSubtitle = "Come back tomorrow! ⏳";''');

    content = content.replaceAll(r'_lockTitle = "Taking a breather!";\n            _lockSubtitle = "0$remaining:00";',
    '''_lockTitle = "Taking a breather!";
            _lockSubtitle = "0\$remaining:00";''');

    // Also fix the mangled emoji in that comment if it exists
    content = content.replaceAll('â ³', '⏳');

    file.writeAsStringSync(content, encoding: utf8);
  }
}

