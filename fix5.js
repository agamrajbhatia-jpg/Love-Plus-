const fs = require('fs');

const livePath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/live_card_game_screen.dart';
let live = fs.readFileSync(livePath, 'utf8');

const regex = /  Future<void> _leaveSession\(\) async {[\s\S]*?if \(coupleId == null \|\| uid == null\) return;/;
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

live = live.replace(regex, goodLeave);
fs.writeFileSync(livePath, live, 'utf8');
console.log('Fixed leaveSession');
