const fs = require('fs');

const gzsPath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(gzsPath, 'utf8');

const badTap = `    return BouncingButton(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCardGameScreen(deckName: title)));
      },`;
const goodTap = `    return BouncingButton(
      onTap: () {
        _handleGameTap(title, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCardGameScreen(deckName: title)));
        });
      },`;
gzs = gzs.replace(badTap, goodTap);
fs.writeFileSync(gzsPath, gzs, 'utf8');
console.log('Fixed Couple Cards lock check');
