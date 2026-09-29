import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum GameAccessStatus { allowed, cooldownActive, dailyLimitReached }

class PremiumGateService {
  static const String _isPremiumKey = 'is_premium_user';
  static const String _dailySessionsKey = 'daily_sessions_map'; 
  static const String _lastSessionDateKey = 'last_session_date';
  static const String _photoGenCountKey = 'photo_generation_count';
  
  // The Free Tier Limits
  static const int maxFreeDailySessions = 2;
  static const int maxFreePhotosTotal = 4;

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPremiumKey) ?? false;
  }

  static Future<void> upgradeToPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, true);
  }

  static Future<GameAccessStatus> checkGameAccess(String gameName) async {
    if (await isPremium()) return GameAccessStatus.allowed;
    if (gameName == 'Tic Tac Toe') return GameAccessStatus.allowed;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString(_lastSessionDateKey) ?? '';

    // If it's a new day, clear all saved play counts and timestamps
    if (today != lastDate) {
      await prefs.setString(_lastSessionDateKey, today);
      await prefs.setString(_dailySessionsKey, '{}');
      // Clear all cooldown timestamps
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('last_launch_time_')) {
          await prefs.remove(key);
        }
      }
      return GameAccessStatus.allowed;
    }

    // Read the last played timestamp for gameName
    final lastLaunchTimeStr = prefs.getString('last_launch_time_$gameName');
    if (lastLaunchTimeStr != null) {
      final lastLaunch = DateTime.parse(lastLaunchTimeStr);
      if (DateTime.now().difference(lastLaunch).inMinutes < 5) {
        return GameAccessStatus.cooldownActive;
      }
    }

    // Read the daily play count for gameName
    final sessionsJson = prefs.getString(_dailySessionsKey) ?? '{}';
    Map<String, dynamic> sessionsMap = jsonDecode(sessionsJson);
    
    final currentSessions = (sessionsMap[gameName] as int?) ?? 0;
    if (currentSessions >= maxFreeDailySessions) {
      return GameAccessStatus.dailyLimitReached;
    }
    
    return GameAccessStatus.allowed;
  }

  static Future<void> recordGameSession(String gameName) async {
    if (gameName == 'Tic Tac Toe') return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save current timestamp for the 5-min cooldown
    await prefs.setString('last_launch_time_$gameName', DateTime.now().toIso8601String());

    if (await isPremium()) return;

    // Increment specific game's daily play count
    final sessionsJson = prefs.getString(_dailySessionsKey) ?? '{}';
    Map<String, dynamic> sessionsMap = jsonDecode(sessionsJson);
    
    final currentSessions = (sessionsMap[gameName] as int?) ?? 0;
    sessionsMap[gameName] = currentSessions + 1;
    
    await prefs.setString(_dailySessionsKey, jsonEncode(sessionsMap));
  }

  static Future<bool> canGeneratePhoto() async {
    if (await isPremium()) return true;
    
    final prefs = await SharedPreferences.getInstance();
    final currentPhotos = prefs.getInt(_photoGenCountKey) ?? 0;
    return currentPhotos < maxFreePhotosTotal;
  }

  static Future<void> recordPhotoGeneration() async {
    if (await isPremium()) return;
    
    final prefs = await SharedPreferences.getInstance();
    final currentPhotos = prefs.getInt(_photoGenCountKey) ?? 0;
    await prefs.setInt(_photoGenCountKey, currentPhotos + 1);
  }
}

