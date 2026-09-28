const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/providers/app_state.dart';
let code = fs.readFileSync(path, 'utf8');

const oldFunc = `  Future<void> generateCode() async {
    if (currentUid == null) return;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final code = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    
    connectionCode = code;
    notifyListeners();
    await FirebaseFirestore.instance.collection('users').doc(currentUid).update({'connectionCode': code});
  }`;

const newFunc = `  Future<void> generateCode() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? currentUid;
      if (uid == null) {
        print('Generate Code Error: User ID is null');
        return;
      }
      
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rnd = Random();
      final code = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      
      // Ensure the generated code is actually being saved to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'connectionCode': code});
      
      // Successfully generated and saved, now assign to state variable and update UI
      currentUid = uid;
      connectionCode = code;
      notifyListeners();
    } catch (e) {
      print('Generate Code Error: $e');
    }
  }`;

if (code.includes(oldFunc)) {
  code = code.replace(oldFunc, newFunc);
  
  if (!code.includes("import 'package:firebase_auth/firebase_auth.dart';")) {
    code = `import 'package:firebase_auth/firebase_auth.dart';\n` + code;
  }
  
  fs.writeFileSync(path, code, 'utf8');
  console.log('Fixed generateCode in AppState');
} else {
  console.log('Could not find generateCode');
}
