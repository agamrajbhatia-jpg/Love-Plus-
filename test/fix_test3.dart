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
    content = content.replaceAll(r'setState(() {\n          _isLocked = true;\n          _lockTitle = "Daily Limit Reached";\n          _lockSubtitle = "Come back tomorrow! ⏳";', 
    '''setState(() {
          _isLocked = true;
          _lockTitle = "Daily Limit Reached";
          _lockSubtitle = "Come back tomorrow! ⏳";''');

    file.writeAsStringSync(content, encoding: utf8);
  }
}

