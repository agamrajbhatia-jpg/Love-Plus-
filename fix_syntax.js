const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

gzs = gzs.replace(`final List<dynamic> questions = data['questions'] ?? [];`, `final List<String> questions = (data['questions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];`);

gzs = gzs.replace(/title\.replaceAll\(' ', '\n'\),/, `title.replaceAll(' ', '\\n'),`);

fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed syntax errors');
