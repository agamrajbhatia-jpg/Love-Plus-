import 'package:cloud_firestore/cloud_firestore.dart';
import 'premium_gate_service.dart';
import 'package:intl/intl.dart';

enum GameAccessStatus { allowed, cooldownActive, dailyLimitReached }

class GateResponse {
  final GameAccessStatus status;
  final int remainingMinutes;
  final DateTime? lastPlayedAt;
  final int playCount;
  GateResponse(this.status, [this.remainingMinutes = 0, this.lastPlayedAt, this.playCount = 0]);
}

class FirebaseGateService {
  static const int maxFreeDailySessions = 2;
  static const int maxFreePhotosTotal = 4;
  
  static String _getDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String getSafeGameName(String gameName) {
    return gameName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  }

  static Future<GateResponse> checkGameAccess(String gameName, String coupleId, String userId) async {
    final dateStr = _getDateString();
    final docId = "${dateStr}_${getSafeGameName(gameName)}_$userId";
    
    final docRef = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('daily_limits')
        .doc(docId);
        
    final snap = await docRef.get();
    if (!snap.exists) return GateResponse(GameAccessStatus.allowed, 0, null, 0);
    
    final data = snap.data()!;
    final lastPlayedAt = data['lastPlayedAt'] as Timestamp?;
    final playCount = data['playCount'] as int? ?? 0;
    
    if (playCount == 0) {
      return GateResponse(GameAccessStatus.allowed, 0, lastPlayedAt?.toDate(), playCount);
    }
    
    if (playCount == 1) {
      if (lastPlayedAt != null) {
        final diff = DateTime.now().difference(lastPlayedAt.toDate()).inMinutes;
        if (diff < 5) {
          return GateResponse(GameAccessStatus.cooldownActive, 5 - diff, lastPlayedAt.toDate(), playCount);
        }
      }
      return GateResponse(GameAccessStatus.allowed, 0, lastPlayedAt?.toDate(), playCount);
    }
    
    // playCount >= 2
    return GateResponse(GameAccessStatus.dailyLimitReached, 0, lastPlayedAt?.toDate(), playCount);
  }

  static Future<void> recordGameSession(String gameName, String coupleId, String userId) async {
    final dateStr = _getDateString();
    final docId = "${dateStr}_${getSafeGameName(gameName)}_$userId";
    
    final docRef = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('daily_limits')
        .doc(docId);
        
    await docRef.set({
      'playCount': FieldValue.increment(1),
      'lastPlayedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<bool> checkPhotoAccess(String coupleId, String userId) async {
    final isPremium = await PremiumGateService.isPremium();
    final maxAllowed = isPremium ? 5 : 1;

    final dateStr = _getDateString();
    final docId = "${dateStr}_photo_gen_$userId";
    
    final docRef = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('daily_limits')
        .doc(docId);
        
    final snap = await docRef.get();
    if (!snap.exists) return true;
    
    final data = snap.data()!;
    final playCount = data['playCount'] as int? ?? 0;
    
    return playCount < maxAllowed;
  }

  static Future<void> recordPhotoGeneration(String coupleId, String userId) async {
    final dateStr = _getDateString();
    final docId = "${dateStr}_photo_gen_$userId";
    
    final docRef = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('daily_limits')
        .doc(docId);
        
    await docRef.set({
      'playCount': FieldValue.increment(1),
      'lastPlayedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<bool> checkCustomCreationAccess(String coupleId, String userId) async {
    final isPremium = await PremiumGateService.isPremium();
    if (isPremium) return true;

    final dateStr = _getDateString();
    final docId = "${dateStr}_$userId";
    
    final docSnap = await FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('custom_limits')
        .doc(docId)
        .get();
        
    return !docSnap.exists;
  }

  static Future<void> recordCustomCreation(String coupleId, String userId) async {
    final dateStr = _getDateString();
    final docId = "${dateStr}_$userId";
    
    await FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('custom_limits')
        .doc(docId)
        .set({
      'created': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<int> getDailySeed(String gameName, String coupleId) async {
    final safeName = getSafeGameName(gameName);
    final dateStr = _getDateString();
    
    // We want the same seed for both users today
    int maxPlayCount = 0;
    
    final query = await FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('daily_limits')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: "${dateStr}_${safeName}_")
        .where(FieldPath.documentId, isLessThan: "${dateStr}_${safeName}_\uf8ff")
        .get();
        
    for (var doc in query.docs) {
      final playCount = doc.data()['playCount'] as int? ?? 0;
      if (playCount > maxPlayCount) {
        maxPlayCount = playCount;
      }
    }
    
    // The day number, coupleId hash, and maxPlayCount determine the deck
    final day = DateTime.now().day;
    return coupleId.hashCode ^ day ^ maxPlayCount;
  }
}
