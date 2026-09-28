import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/app_state.dart';

class PointService {
  static Future<void> awardPoints(BuildContext context, int points) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final coupleId = appState.currentCoupleId;
    
    if (coupleId == null) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('couples').doc(coupleId);
      
      await docRef.set({
        'couple_points': FieldValue.increment(points),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error awarding points: $e");
    }
  }
}
