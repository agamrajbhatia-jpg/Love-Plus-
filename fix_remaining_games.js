const fs = require('fs');

function fixScenario() {
  const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/scenario_scale_screen.dart';
  let code = fs.readFileSync(path, 'utf8');

  const oldCode = `    final vaultList = LibraryVault.games['Scenario Scales']!;
    int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
    
    List<Map<String, dynamic>> sliced = [];
    for (int i = 0; i < 10; i++) {
      sliced.add({"scenario": vaultList[(vaultIndex + i) % vaultList.length]});
    }`;

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
  
  if (code.includes(oldCode)) {
    code = code.replace(oldCode, newCode);
    if (!code.includes('dart:math')) {
      code = code.replace(`import 'package:flutter/material.dart';`, `import 'package:flutter/material.dart';\nimport 'dart:math' as math;`);
    }
    fs.writeFileSync(path, code, 'utf8');
    console.log('Fixed scenario');
  }
}

function fixExpose() {
  const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/expose_us_screen.dart';
  let code = fs.readFileSync(path, 'utf8');

  const oldCode = `    final vaultList = LibraryVault.games['Expose Us']!;
    int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
    
    List<String> sliced = [];
    for (int i = 0; i < 10; i++) {
      sliced.add(vaultList[(vaultIndex + i) % vaultList.length]);
    }`;

  const newCode = `    final appState = Provider.of<AppState>(context, listen: false);
    final coupleId = appState.currentCoupleId ?? 'default';
    int seed = coupleId.hashCode ^ DateTime.now().day;
    if (coupleId != 'default') {
      seed = await FirebaseGateService.getDailySeed('Expose Us', coupleId);
    }
    
    final vaultList = List<String>.from(LibraryVault.games['Expose Us']!);
    vaultList.shuffle(math.Random(seed));
    
    List<String> sliced = [];
    for (String item in vaultList.take(5)) {
      sliced.add(item);
    }`;
  
  if (code.includes(oldCode)) {
    code = code.replace(oldCode, newCode);
    if (!code.includes('dart:math')) {
      code = code.replace(`import 'package:flutter/material.dart';`, `import 'package:flutter/material.dart';\nimport 'dart:math' as math;`);
    }
    fs.writeFileSync(path, code, 'utf8');
    console.log('Fixed expose');
  }
}

fixScenario();
fixExpose();
