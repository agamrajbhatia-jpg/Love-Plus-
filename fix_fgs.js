const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/services/firebase_gate_service.dart';
let fgs = fs.readFileSync(path, 'utf8');

const regex = /class GateResponse \{\r?\n  final GameAccessStatus status;\r?\n  final int remainingMinutes;\r?\n  GateResponse\(this\.status, \[this\.remainingMinutes = 0\]\);\r?\n\}/;
fgs = fgs.replace(regex, `class GateResponse {
  final GameAccessStatus status;
  final int remainingMinutes;
  final DateTime? lastPlayedAt;
  final int playCount;
  GateResponse(this.status, [this.remainingMinutes = 0, this.lastPlayedAt, this.playCount = 0]);
}`);

fs.writeFileSync(path, fgs, 'utf8');
console.log('Fixed GateResponse');
