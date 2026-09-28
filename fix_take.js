const fs = require('fs');
const gamesDir = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/';
const files = fs.readdirSync(gamesDir);

for (const file of files) {
  if (file.endsWith('.dart')) {
    const p = gamesDir + file;
    let code = fs.readFileSync(p, 'utf8');
    if (code.includes('.take(10)')) {
      code = code.replace(/\.take\(10\)/g, '.take(5)');
      fs.writeFileSync(p, code, 'utf8');
      console.log('Fixed take(10) in ' + file);
    }
  }
}
