const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/providers/app_state.dart';
let code = fs.readFileSync(path, 'utf8');

const oldFunc = `await FirebaseFirestore.instance.collection('users').doc(uid).set({'connectionCode': code}, SetOptions(merge: true));`;
const newFunc = `await FirebaseFirestore.instance.collection('users').doc(uid).set({'connectionCode': code}, SetOptions(merge: true)).timeout(const Duration(seconds: 5));`;

if (code.includes(oldFunc)) {
  code = code.replace(oldFunc, newFunc);
  
  // also make it throw the error
  const oldCatch = `} catch (e) {
      print('Generate Code Error: $e');
    }`;
  const newCatch = `} catch (e) {
      print('Generate Code Error: $e');
      rethrow;
    }`;
  code = code.replace(oldCatch, newCatch);
  
  fs.writeFileSync(path, code, 'utf8');
  console.log('Fixed generateCode timeout');
} else {
  console.log('Could not find generateCode call');
}
