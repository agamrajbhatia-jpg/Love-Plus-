const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

gzs = gzs.replace(/"title": "Would You Rather\?",/g, `"title": "Would You Rather",`);
gzs = gzs.replace(/"title": "How Well Do You Know Me\?",/g, `"title": "How Well Do You Know Me",`);
gzs = gzs.replace(/"title": "Blindly Ranking Date Ideas",/g, `"title": "Blind Ranking Date Ideas",`);

fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed game titles matching');
