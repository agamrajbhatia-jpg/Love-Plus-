const fs = require('fs');

const gzsPath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(gzsPath, 'utf8');
gzs = gzs.replace(`_handleGameTap(title, () {`, `_handleGameTap('Couple Cards', () {`);
fs.writeFileSync(gzsPath, gzs, 'utf8');

const livePath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/live_card_game_screen.dart';
let live = fs.readFileSync(livePath, 'utf8');
live = live.replace(`await FirebaseGateService.recordGameSession(widget.deckName, coupleId, uid);`, `await FirebaseGateService.recordGameSession('Couple Cards', coupleId, uid);`);
fs.writeFileSync(livePath, live, 'utf8');
console.log('Fixed Couple Cards shared cooldown');
