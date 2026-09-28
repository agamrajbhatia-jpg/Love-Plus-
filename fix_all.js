const fs = require('fs');
const path = require('path');

const gzsPath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(gzsPath, 'utf8');

// 1. Fix Emojis
gzs = gzs.replace(/ðŸ”’/g, '🔒');
gzs = gzs.replace(/âœ✨/g, '✨'); // Wait, the output was âœ¨
gzs = gzs.replace(/âœ¨/g, '✨');
gzs = gzs.replace(/ðŸ’Œ/g, '💌');
gzs = gzs.replace(/ðŸŽˆ/g, '🎈');
gzs = gzs.replace(/â ¤ï¸ â€ ðŸ”¥/g, '💬');
gzs = gzs.replace(/ðŸƒ /g, '🎯');
gzs = gzs.replace(/ðŸŒŒ/g, '💡');
gzs = gzs.replace(/âš”ï¸ /g, '⚔️');
gzs = gzs.replace(/🤷‍♀️/g, '🌶️'); // Spicy & Sweet

// 2. Fix BOTTOM OVERFLOWED in _GameCard
const gameCardOld =             Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
                    ]
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              flex: 1,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),;

const gameCardNew =             Expanded(
              flex: 2,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
                      ]
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),;

gzs = gzs.replace(gameCardOld, gameCardNew);

// 3. Update Gatekeeper in _handleGameTap
const handleGameTapOld =   void _handleGameTap(String gameName, VoidCallback action) {
    action();
  };

const handleGameTapNew =   void _handleGameTap(String gameName, VoidCallback action) async {
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    if (coupleId == null || uid == null) return;
    
    final response = await FirebaseGateService.checkGameAccess(gameName, coupleId, uid);
    if (response.status == GameAccessStatus.cooldownActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Wait \ minutes to play again', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else if (response.status == GameAccessStatus.dailyLimitReached) {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumBenefitsScreen()));
      }
    } else {
      action();
    }
  };

gzs = gzs.replace(handleGameTapOld, handleGameTapNew);
fs.writeFileSync(gzsPath, gzs, 'utf8');

// 4. Inject Trigger in game screens
const screensDir = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/';
const gamesMap = {
  'would_you_rather_screen.dart': 'Would You Rather',
  'how_well_do_you_know_me_screen.dart': 'How Well Do You Know Me',
  'scenario_scale_screen.dart': 'Scenario Scale',
  'how_mad_screen.dart': 'How Mad?',
  'expose_us_screen.dart': 'Expose Us'
};

for (const [file, safeName] of Object.entries(gamesMap)) {
  const p = path.join(screensDir, file);
  if (fs.existsSync(p)) {
    let content = fs.readFileSync(p, 'utf8');
    
    // Inject import if not present
    if (!content.includes('firebase_gate_service.dart')) {
      content = "import '../../services/firebase_gate_service.dart';\n" + content;
    }

    // Insert recordGameSession before showDialog
    const showDialogIndex = content.lastIndexOf('showDialog(');
    if (showDialogIndex > -1 && !content.includes('recordGameSession')) {
      const injectStr =       final currentAppState = context.read<AppState>();
      if (currentAppState.currentCoupleId != null && currentAppState.currentUid != null) {
        await FirebaseGateService.recordGameSession('', currentAppState.currentCoupleId!, currentAppState.currentUid!);
      }\n      ;
      content = content.slice(0, showDialogIndex) + injectStr + content.slice(showDialogIndex);
      fs.writeFileSync(p, content, 'utf8');
      console.log('Injected trigger in ' + file);
    }
  }
}
console.log('Done!');
