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
    
    // 1. Add import
    if (!content.contains("premium_lock_screen.dart")) {
      content = content.replaceFirst(
        "import '../../data/library_vault.dart';", 
        "import '../../data/library_vault.dart';\nimport '../../widgets/premium_lock_screen.dart';"
      );
    }

    // 2. State variables
    content = content.replaceAll(
      'String _lockTitle = "";\n  String _lockSubtitle = "";', 
      'bool _isDailyLock = false;\n  DateTime? _unlockTime;'
    );
    
    // It's possible some have \r\n, so let's be robust:
    content = content.replaceAll(
      RegExp(r'String _lockTitle = "";\s*String _lockSubtitle = "";'),
      'bool _isDailyLock = false;\n  DateTime? _unlockTime;'
    );

    // 3. Daily Limit logic
    content = content.replaceAll(
      RegExp(r'_lockTitle = "Daily Limit Reached";\s*_lockSubtitle = "Come back tomorrow! ⏳";'),
      '_isDailyLock = true;\n          _unlockTime = DateTime(now.year, now.month, now.day + 1);'
    );

    // 4. Breather logic
    content = content.replaceAll(
      RegExp(r'_lockTitle = "Taking a breather!";\s*_lockSubtitle = "0\$remaining:00";'),
      '_isDailyLock = false;\n            _unlockTime = lastTime.add(const Duration(minutes: 5));'
    );

    // 5. Replace UI block
    final oldUiRegex = RegExp(r'if \(_isLocked\) \{[\s\S]*?\}\s*(?=\n\s*(final|return Scaffold|final bool))');
    
    final newUi = '''if (_isLocked && _unlockTime != null) {
      return PremiumLockScreen(
        isDailyLimit: _isDailyLock,
        unlockTime: _unlockTime!,
      );
    }''';

    content = content.replaceFirst(oldUiRegex, newUi);

    file.writeAsStringSync(content);
    print("Updated \$filename");
  }
}

