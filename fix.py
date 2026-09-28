import re

with open("lib/screens/modes/game_zone_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Find where we inserted the stream builder end
target_str = """                    );
                  }
                ),"""

replacement = """                    );
                  }
                ),
                const SizedBox(height: 30),
                _buildCustomGamesInbox(),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); // Wipes all local tracking immediately
                    print("DEBUG: All limits reset. You can test again.");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("All limits reset!"))
                      );
                    }
                  },
                  child: const Text("Reset All Limits (Debug)"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreboardWidget extends StatelessWidget {
  final int userScore;
  final int partnerScore;
  final String partnerName;

  const _ScoreboardWidget({
    required this.userScore,
    required this.partnerScore,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 20,
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScorePill(name: "You", score: userScore, color: const Color(0xFFFF6B6B)),
          const SizedBox(width: 8),
          Text(
            "??",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          _ScorePill(name: partnerName, score: partnerScore, color: const Color(0xFF4ECDC4)),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String name;
  final int score;
  final Color color;

  const _ScorePill({required this.name, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Row(
          children: [
            Text(
              "$score",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: color, blurRadius: 12)]
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.favorite, color: Colors.pinkAccent, size: 14),
          ],
        )
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final VoidCallback? onTapAction;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: () {
        if (onTapAction != null) {
          onTapAction!();
        } else {
          showDialog(
            context: context,
            barrierColor: Colors.black12,
            builder: (dialogContext) {
              Future.delayed(const Duration(seconds: 2), () {
                if (dialogContext.mounted) Navigator.pop(dialogContext);"""

idx = content.find(target_str)
if idx != -1:
    end_idx = idx + len(target_str)
    
    # We also need to strip out the garbage that was left over from the greedy match.
    # The garbage starts right after `target_str` and goes up to the start of the SafeArea.
    # The garbage is: `                  ),\n                ),\n              );\n            }\n          );\n        }\n      },`
    
    # Let's find `return SafeArea(` after end_idx
    safe_area_idx = content.find("              return SafeArea(", end_idx)
    if safe_area_idx != -1:
        new_content = content[:end_idx] + "\n" + replacement + "\n" + content[safe_area_idx:]
        with open("lib/screens/modes/game_zone_screen.dart", "w", encoding="utf-8") as f:
            f.write(new_content)
        print("Success")
    else:
        print("Failed to find SafeArea")
else:
    print("Failed to find target")
