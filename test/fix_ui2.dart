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
    
    final colorRegex = RegExp(r'colors:\s*(const \[Color\([^)]+\),\s*Color\([^)]+\)\])');
    final allMatches = colorRegex.allMatches(content);
    if (allMatches.length > 0) {
        final realColors = allMatches.first.group(1);

        final newUi = '''if (_isLocked) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: DynamicBackground(
          colors: $realColors,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                      )
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_clock,
                        color: Colors.white,
                        size: 56,
                        shadows: [
                          Shadow(color: Colors.pinkAccent, blurRadius: 20)
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _lockTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _lockSubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: _lockSubtitle.contains(":") ? 60 : 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(color: Colors.white.withOpacity(0.8), blurRadius: 15)
                          ]
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }''';

        final blockRegex = RegExp(r'if \(_isLocked\) \{[\s\S]*?\}\s*(?=\n\s*(final|return Scaffold|final bool))');
        content = content.replaceFirst(blockRegex, newUi);

        file.writeAsStringSync(content);
        print("Updated \$filename");
    }
  }
}
