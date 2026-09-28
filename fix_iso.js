const fs = require('fs');

const gzsPath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(gzsPath, 'utf8');
gzs = gzs.replace(`_handleGameTap('Couple Cards', () {`, `_handleGameTap(title, () {`);
fs.writeFileSync(gzsPath, gzs, 'utf8');

const livePath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/live_card_game_screen.dart';
let live = fs.readFileSync(livePath, 'utf8');
live = live.replace(`await FirebaseGateService.recordGameSession('Couple Cards', coupleId, uid);`, `await FirebaseGateService.recordGameSession(widget.deckName, coupleId, uid);`);
fs.writeFileSync(livePath, live, 'utf8');
console.log('Restored isolated timers');
