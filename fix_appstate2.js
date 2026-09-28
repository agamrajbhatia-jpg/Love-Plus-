const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/providers/app_state.dart';
let code = fs.readFileSync(path, 'utf8');

const oldUpdate = "await FirebaseFirestore.instance.collection('users').doc(uid).update({'connectionCode': code});";
const newUpdate = "await FirebaseFirestore.instance.collection('users').doc(uid).set({'connectionCode': code}, SetOptions(merge: true));";

if (code.includes(oldUpdate)) {
  code = code.replace(oldUpdate, newUpdate);
  fs.writeFileSync(path, code, 'utf8');
  console.log('Changed update to set with merge');
} else {
  console.log('Could not find update call');
}
