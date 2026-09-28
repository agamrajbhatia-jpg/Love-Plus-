const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/providers/app_state.dart';
let code = fs.readFileSync(path, 'utf8');

code = code.replace(
`  void addGamePoints(int points, {required bool isUser}) {
    if (isUser) {
      userGameScore += points;
    } else {
      partnerGameScore += points;
    }
    notifyListeners();
  }`,
`  void addGamePoints(int points, {required bool isUser}) {
    if (isUser) {
      userGameScore += points;
      if (currentCoupleId != null && currentUid != null) {
        FirebaseFirestore.instance.collection('couples').doc(currentCoupleId).set({
          'score_$currentUid': userGameScore,
        }, SetOptions(merge: true));
      }
    } else {
      partnerGameScore += points;
    }
    notifyListeners();
  }`
);

code = code.replace(
`        if (isPartnerTyping != newIsTyping) {
          isPartnerTyping = newIsTyping;
          notifyListeners();
        }`,
`        if (isPartnerTyping != newIsTyping) {
          isPartnerTyping = newIsTyping;
          notifyListeners();
        }
        
        final newMyScore = data['score_$currentUid'] ?? 0;
        final newPartnerScore = data['score_$partnerUid'] ?? 0;
        if (userGameScore != newMyScore || partnerGameScore != newPartnerScore) {
          userGameScore = newMyScore as int;
          partnerGameScore = newPartnerScore as int;
          notifyListeners();
        }`
);

fs.writeFileSync(path, code, 'utf8');
console.log('Fixed score sync');
