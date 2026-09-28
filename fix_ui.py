import os
import re

games_dir = "lib/screens/games"
files = [
    "would_you_rather_screen.dart",
    "how_well_do_you_know_me_screen.dart",
    "scenario_scale_screen.dart",
    "how_mad_screen.dart",
    "expose_us_screen.dart",
    "ranking_date_ideas_screen.dart"
]

for filename in files:
    filepath = os.path.join(games_dir, filename)
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Add _lockTitle and _lockSubtitle
    content = re.sub(r'String _lockMessage = "";', 
                     'String _lockTitle = "";\n  String _lockSubtitle = "";', 
                     content)

    # 2. Fix the Daily Limit Reached string
    content = re.sub(
        r'setState\(\(\) \{\s*_isLocked = true;\s*_lockMessage = "Daily Limit Reached.\\nCome back tomorrow! [^"]+";',
        'setState(() {\n          _isLocked = true;\n          _lockTitle = "Daily Limit Reached";\n          _lockSubtitle = "Come back tomorrow! ⏳";',
        content
    )

    # 3. Fix the breather string (some have extra spaces or different remaining vars)
    content = re.sub(
        r'setState\(\(\) \{\s*_isLocked = true;\s*_lockMessage = "Taking a breather!\\nNext session unlocks in \$remaining minutes. [^"]+";',
        'setState(() {\n            _isLocked = true;\n            _lockTitle = "Taking a breather!";\n            _lockSubtitle = "0$remaining:00";',
        content
    )

    # 4. Replace the lock UI in build method
    ui_regex = r'if \(_isLocked\) \{[\s\S]*?\}\s*(?:final|return)'
    
    # We need to preserve the colors of the dynamic background!
    # Let's extract the colors first
    color_match = re.search(r'colors:\s*(const \[Color\([^\)]+\), Color\([^\)]+\)\])', content)
    if not color_match:
        # Some files might have different array formats, but they all use const [Color(...), Color(...)]
        print(f"Could not find colors in {filename}")
        continue
    
    colors_str = color_match.group(1)

    new_ui = f'''if (_isLocked) {{
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: DynamicBackground(
          colors: {colors_str},
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2), // Subtle glow
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hourglass_empty,
                        color: Colors.white,
                        size: 48,
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
                          fontSize: _lockSubtitle.contains(":") ? 56 : 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
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
    }}

    '''

    # The regex needs to replace the if (_isLocked) block.
    # We can find `if (_isLocked) { ... }` up to the next `final` or `return Scaffold`.
    content = re.sub(r'if \(_isLocked\) \{[\s\S]*?\}\s*(\n\s*(?:final|return Scaffold))', new_ui + r'\1', content)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
        
print("Done!")
