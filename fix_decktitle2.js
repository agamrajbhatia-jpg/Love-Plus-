const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

// Fix _buildDeckButton text
gzs = gzs.replace(/Text\([\s\S]*?title\.replaceAll\(' ', '\\n'\),[\s\S]*?textAlign: TextAlign\.center,[\s\S]*?style: GoogleFonts\.poppins\(fontSize: 13, fontWeight: FontWeight\.bold, color: Colors\.white, height: 1\.2\),[\s\S]*?\),/, `Flexible(
              child: Text(
                title.replaceAll(' ', '\\n'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
              ),
            ),`);

fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed deck button overflow');
