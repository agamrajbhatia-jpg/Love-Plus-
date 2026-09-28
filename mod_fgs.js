const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/services/firebase_gate_service.dart';
let fgs = fs.readFileSync(path, 'utf8');

fgs = fgs.replace(
`class GateResponse {
  final GameAccessStatus status;
  final int remainingMinutes;
  GateResponse(this.status, [this.remainingMinutes = 0]);
}`,
`class GateResponse {
  final GameAccessStatus status;
  final int remainingMinutes;
  final DateTime? lastPlayedAt;
  final int playCount;
  GateResponse(this.status, [this.remainingMinutes = 0, this.lastPlayedAt, this.playCount = 0]);
}`);

fgs = fgs.replace(
`    if (!snap.exists) return GateResponse(GameAccessStatus.allowed);`,
`    if (!snap.exists) return GateResponse(GameAccessStatus.allowed, 0, null, 0);`);

fgs = fgs.replace(
`    if (lastPlayedAt != null) {
      final diff = DateTime.now().difference(lastPlayedAt.toDate()).inMinutes;
      if (diff < 5 && playCount < 2) {
        return GateResponse(GameAccessStatus.cooldownActive, 5 - diff);
      }
    }
    
    if (playCount >= maxFreeDailySessions) {
      return GateResponse(GameAccessStatus.dailyLimitReached);
    }
    
    return GateResponse(GameAccessStatus.allowed);`,
`    if (playCount >= maxFreeDailySessions) {
      return GateResponse(GameAccessStatus.dailyLimitReached, 0, lastPlayedAt?.toDate(), playCount);
    }

    if (lastPlayedAt != null) {
      final diff = DateTime.now().difference(lastPlayedAt.toDate()).inMinutes;
      if (diff < 5 && playCount < 2) {
        return GateResponse(GameAccessStatus.cooldownActive, 5 - diff, lastPlayedAt.toDate(), playCount);
      }
    }
    
    return GateResponse(GameAccessStatus.allowed, 0, lastPlayedAt?.toDate(), playCount);`);

fs.writeFileSync(path, fgs, 'utf8');
console.log('Modified GateService');
