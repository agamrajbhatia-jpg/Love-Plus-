const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/how_well_do_you_know_me_screen.dart';
let code = fs.readFileSync(path, 'utf8');

code = code.replace(`await FirebaseGateService.recordGameSession('how_well_do_you_know_me'`, `await FirebaseGateService.recordGameSession('How Well Do You Know Me'`);

fs.writeFileSync(path, code, 'utf8');
console.log('Fixed HowWellDoYouKnowMe match');
