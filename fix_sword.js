const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

const regex = /Text\(\r?\n\s+"[^"]*",\r?\n\s+style: const TextStyle\(fontSize: 14\),\r?\n\s+\),/;
gzs = gzs.replace(regex, `Text(
            ' ⚔️ ',
            style: const TextStyle(fontSize: 14),
          ),`);

fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed sword glyph');
