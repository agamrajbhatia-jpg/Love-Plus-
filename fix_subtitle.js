const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

const oldSubtitle = `            Expanded(
              flex: 1,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.9)),
              ),
            ),`;

const newSubtitle = `            Flexible(
              flex: 1,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: GoogleFonts.poppins(fontSize: 9, height: 1.1, color: Colors.white.withOpacity(0.9)),
              ),
            ),`;

gzs = gzs.replace(oldSubtitle, newSubtitle);

fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed subtitle overflow');
