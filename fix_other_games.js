const fs = require('fs');

function fixScreen(file, gameName, dataKey) {
  const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/' + file;
  let code = fs.readFileSync(path, 'utf8');

  const oldCode = `    final vaultList = LibraryVault.games['${gameName}']!;
    int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
    
    List<Map<String, dynamic>> sliced = [];
    for (int i = 0; i < 10; i++) {
      sliced.add({"${dataKey}": vaultList[(vaultIndex + i) % vaultList.length]});
    }`;

  const newCode = `    final appState = Provider.of<AppState>(context, listen: false);
    final coupleId = appState.currentCoupleId ?? 'default';
    int seed = coupleId.hashCode ^ DateTime.now().day;
    if (coupleId != 'default') {
      seed = await FirebaseGateService.getDailySeed('${gameName}', coupleId);
    }
    
    final vaultList = List<String>.from(LibraryVault.games['${gameName}']!);
    vaultList.shuffle(math.Random(seed));
    
    List<Map<String, dynamic>> sliced = [];
    for (String item in vaultList.take(5)) {
      sliced.add({"${dataKey}": item});
    }`;
  
  if (code.includes(oldCode)) {
    code = code.replace(oldCode, newCode);
    if (!code.includes('dart:math')) {
      code = code.replace(`import 'package:flutter/material.dart';`, `import 'package:flutter/material.dart';\nimport 'dart:math' as math;`);
    }
    fs.writeFileSync(path, code, 'utf8');
    console.log('Fixed ' + file);
  } else {
    console.log('String replace failed for ' + file);
  }
}

fixScreen('how_mad_screen.dart', 'How Mad Would You Get', 'scenario');
fixScreen('scenario_scale_screen.dart', 'Scenario Scale', 'scenario');
fixScreen('expose_us_screen.dart', 'Expose Us', 'statement');
