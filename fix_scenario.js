const fs = require('fs');

const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/scenario_scale_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldCodeRegex = /final vaultList = LibraryVault\.games\['Scenario Scales'\]!;\r?\n    int vaultIndex = prefs\.getInt\('vault_index_\$gameKey'\) \?\? 0;\r?\n    \r?\n    List<Map<String, dynamic>> sliced = \[\];\r?\n    for \(int i = 0; i < 10; i\+\+\) \{\r?\n      sliced\.add\(\{"scenario": vaultList\[\(vaultIndex \+ i\) % vaultList\.length\]\}\);\r?\n    \}/;

const newCode = `    final appState = Provider.of<AppState>(context, listen: false);
    final coupleId = appState.currentCoupleId ?? 'default';
    int seed = coupleId.hashCode ^ DateTime.now().day;
    if (coupleId != 'default') {
      seed = await FirebaseGateService.getDailySeed('Scenario Scales', coupleId);
    }
    
    final vaultList = List<String>.from(LibraryVault.games['Scenario Scales']!);
    vaultList.shuffle(math.Random(seed));
    
    List<Map<String, dynamic>> sliced = [];
    for (String item in vaultList.take(5)) {
      sliced.add({"scenario": item});
    }`;

code = code.replace(oldCodeRegex, newCode);
if (!code.includes('dart:math')) {
  code = code.replace(`import 'package:flutter/material.dart';`, `import 'package:flutter/material.dart';\nimport 'dart:math' as math;`);
}
fs.writeFileSync(path, code, 'utf8');
console.log('Fixed scenario using regex');
