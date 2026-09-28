const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

const oldTitle = `            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]
                  ),
                ),
              ),
            ),`;

const newTitle = `            Expanded(
              flex: 2,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]
                ),
              ),
            ),`;

const oldSubtitle = `            Expanded(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.9)),
                ),
              ),
            ),`;

const newSubtitle = `            Expanded(
              flex: 1,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.9)),
              ),
            ),`;

gzs = gzs.replace(oldTitle, newTitle);
gzs = gzs.replace(oldSubtitle, newSubtitle);

fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed GameCard text');
