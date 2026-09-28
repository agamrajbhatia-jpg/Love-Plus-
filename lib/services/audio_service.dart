import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _isBgmPlaying = false;
  bool _isMuted = false;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      debugPrint("🔇 [AudioService] Audio muted");
    } else {
      debugPrint("🔊 [AudioService] Audio unmuted");
    }
  }

  Future<void> startBgm() async {
    if (_isMuted || _isBgmPlaying) return;
    try {
      // In a real app we'd load an asset. We mock it for now.
      _isBgmPlaying = true;
      debugPrint("🎵 [AudioService] Started cozy BGM loop");
      // await _bgmPlayer.play(AssetSource('audio/bgm_cozy.mp3'), volume: 0.5);
      // await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint("Failed to play BGM: $e");
    }
  }

  Future<void> pauseBgm() async {
    if (!_isBgmPlaying) return;
    try {
      _isBgmPlaying = false;
      debugPrint("⏸️ [AudioService] Paused BGM loop");
      // await _bgmPlayer.pause();
    } catch (e) {
      debugPrint("Failed to pause BGM: $e");
    }
  }

  Future<void> playEatingSound() async {
    if (_isMuted) return;
    debugPrint("🔊 [AudioService] Played eating sound (nom nom)");
    // await _sfxPlayer.play(AssetSource('audio/eat.mp3'));
  }

  Future<void> playKissSound() async {
    if (_isMuted) return;
    debugPrint("🔊 [AudioService] Played kiss sound (mwah)");
    // await _sfxPlayer.play(AssetSource('audio/kiss.mp3'));
  }

  Future<void> playLaughSound() async {
    if (_isMuted) return;
    debugPrint("🔊 [AudioService] Played laugh sound (hehe)");
    // await _sfxPlayer.play(AssetSource('audio/laugh.mp3'));
  }

  Future<void> playLevelUpSound() async {
    if (_isMuted) return;
    debugPrint("🔊 [AudioService] Played level up sound (tada!)");
    // await _sfxPlayer.play(AssetSource('audio/levelup.mp3'));
  }
}
