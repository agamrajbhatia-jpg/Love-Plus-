const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/would_you_rather_screen.dart';
let wyr = fs.readFileSync(path, 'utf8');

wyr = wyr.replace(`      vaultList = vaultList.take(5).toList();
    }
    
    List<Map<String, String>> sliced = [];
    for (int i = 0; i < itemsCount; i++) {`, `      vaultList = vaultList.take(5).toList();
    }
    
    int actualCount = vaultList.length;
    List<Map<String, String>> sliced = [];
    for (int i = 0; i < actualCount; i++) {`);

fs.writeFileSync(path, wyr, 'utf8');
console.log('Fixed Would You Rather RangeError');
