const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

gzs = gzs.replace(
`                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,`,
`                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontSize: 16,`
);

gzs = gzs.replace(
`                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11`,
`                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(fontSize: 11`
);

fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed GameCard text overflow');
