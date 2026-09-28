const fs = require('fs');

// Fix GameZoneScreen overflow
const gzsPath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(gzsPath, 'utf8');
gzs = gzs.replace(`        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title.replaceAll(' ', '\\n'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.1,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
                ]
              ),
            ),
          ],
        ),`, `        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                title.replaceAll(' ', '\\n'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
                  ]
                ),
              ),
            ],
          ),
        ),`);
fs.writeFileSync(gzsPath, gzs, 'utf8');

// Fix live_card_game_screen.dart dispose crash
const livePath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/live_card_game_screen.dart';
let live = fs.readFileSync(livePath, 'utf8');

const badLeave = `  Future<void> _leaveSession() async {
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    if (coupleId == null || uid == null) return;`;
    
const goodLeave = `  String? _cachedCoupleId;
  String? _cachedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedCoupleId = context.read<AppState>().currentCoupleId;
    _cachedUid = context.read<AppState>().currentUid;
  }

  Future<void> _leaveSession() async {
    final coupleId = _cachedCoupleId;
    final uid = _cachedUid;
    if (coupleId == null || uid == null) return;`;

live = live.replace(badLeave, goodLeave);
fs.writeFileSync(livePath, live, 'utf8');
console.log('Fixed both');
