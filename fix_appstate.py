import os

path = "c:/Users/agamr/Documents/CoupleApp/lib/providers/app_state.dart"
with open(path, "r", encoding="utf-8") as f:
    code = f.read()

old_func = """  Future<bool> linkWithPartner(String code, [String? pName]) async {
    if (currentUid == null) return false;
    
    final query = await FirebaseFirestore.instance.collection('users').where('connectionCode', isEqualTo: code).limit(1).get();
    
    if (query.docs.isEmpty) return false;
    
    final partnerDoc = query.docs.first;
    final partnerUid = partnerDoc.id;
    
    if (partnerUid == currentUid) return false; // can't link to self
    
    final uids = [currentUid!, partnerUid]..sort();
    final coupleId = '${uids[0]}_${uids[1]}';
    
    final batch = FirebaseFirestore.instance.batch();
    
    final coupleRef = FirebaseFirestore.instance.collection('couples').doc(coupleId);
    batch.set(coupleRef, {
      'user1': uids[0],
      'user2': uids[1],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    final myRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    batch.update(myRef, {
      'coupleId': coupleId,
      'partnerName': pName ?? "Lover",
      'linkedPartnerUid': partnerUid,
    });
    
    final pRef = FirebaseFirestore.instance.collection('users').doc(partnerUid);
    batch.update(pRef, {
      'coupleId': coupleId,
      'partnerName': userName ?? "Lover", 
      'linkedPartnerUid': currentUid,
    });
    
    await batch.commit();
    return true;
  }"""

new_func = """  Future<void> linkWithPartner(String code, [String? pName]) async {
    if (currentUid == null) throw Exception('User ID is null');
    
    final safeCode = code.trim().toUpperCase();
    
    final query = await FirebaseFirestore.instance.collection('users').where('connectionCode', isEqualTo: safeCode).limit(1).get();
    
    if (query.docs.isEmpty) throw Exception('Invalid connection code. Partner not found.');
    
    final partnerDoc = query.docs.first;
    final partnerUid = partnerDoc.id;
    
    if (partnerUid == currentUid) throw Exception('You cannot link with your own code.');
    
    final uids = [currentUid!, partnerUid]..sort();
    final coupleId = '${uids[0]}_${uids[1]}';
    
    final batch = FirebaseFirestore.instance.batch();
    
    final coupleRef = FirebaseFirestore.instance.collection('couples').doc(coupleId);
    batch.set(coupleRef, {
      'user1': uids[0],
      'user2': uids[1],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    final myRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    batch.update(myRef, {
      'coupleId': coupleId,
      'partnerName': pName ?? "Lover",
      'partnerId': partnerUid,
      'linkedPartnerUid': partnerUid,
    });
    
    final pRef = FirebaseFirestore.instance.collection('users').doc(partnerUid);
    batch.update(pRef, {
      'coupleId': coupleId,
      'partnerName': userName ?? "Lover", 
      'partnerId': currentUid,
      'linkedPartnerUid': currentUid,
    });
    
    await batch.commit();
  }"""

if old_func in code:
    code = code.replace(old_func, new_func)
    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Fixed linkWithPartner")
else:
    print("Could not find linkWithPartner")
