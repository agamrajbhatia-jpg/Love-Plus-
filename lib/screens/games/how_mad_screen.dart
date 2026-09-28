import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/bouncing_button.dart';
import '../../widgets/dynamic_background.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_gate_service.dart';
import 'dart:math' as math;
import '../../data/library_vault.dart';
import '../../widgets/premium_lock_screen.dart';

import '../../widgets/game_skeleton_loader.dart';
import 'dart:math';

enum HowMadMode { setup, play }

class HowMadScreen extends StatefulWidget {
  final Map<String, dynamic>? challengeToPlay;

  const HowMadScreen({super.key, this.challengeToPlay});

  @override
  State<HowMadScreen> createState() => _HowMadScreenState();
}

class _HowMadScreenState extends State<HowMadScreen> {
  int _currentScenarioIndex = 0;
  double _currentSliderValue = 1.0;
  List<Map<String, dynamic>> _activeScenarios = [];
  bool _isLoading = true;
  bool _isLocked = false;
  bool _isDailyLock = false;
  DateTime? _unlockTime;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    final gameKey = 'howMad';
    
    final lastDate = prefs.getString('last_played_date_$gameKey');
    int sessionsToday = prefs.getInt('sessions_played_today_$gameKey') ?? 0;
    
    if (lastDate != today) {
      sessionsToday = 0;
      await prefs.setString('last_played_date_$gameKey', today);
      await prefs.setInt('sessions_played_today_$gameKey', 0);
    }
    
    if (sessionsToday >= 2) {
      if (mounted) {
        setState(() {
          _isLocked = true;
          _isDailyLock = true;
          _unlockTime = DateTime(now.year, now.month, now.day + 1);
          _isLoading = false;
        });
      }
      return;
    } else if (sessionsToday == 1) {
      final lastTimestamp = prefs.getInt('last_session_timestamp_$gameKey') ?? 0;
      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
      final diff = now.difference(lastTime);
      if (diff.inMinutes < 5) {
        final remaining = 5 - diff.inMinutes;
        if (mounted) {
          setState(() {
            _isLocked = true;
            _isDailyLock = false;
            _unlockTime = lastTime.add(const Duration(minutes: 5));
            _isLoading = false;
          });
        }
        return;
      }
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final coupleId = appState.currentCoupleId ?? 'default';
    int seed = coupleId.hashCode ^ DateTime.now().day;
    if (coupleId != 'default') {
      seed = await FirebaseGateService.getDailySeed('How Mad Would You Get', coupleId);
    }
    
    final vaultList = List<String>.from(LibraryVault.games['How Mad Would You Get']!);
    vaultList.shuffle(math.Random(seed));
    
    List<Map<String, dynamic>> sliced = [];
    for (String item in vaultList.take(5)) {
      sliced.add({"scenario": item});
    }

    if (mounted) {
      setState(() {
        _activeScenarios = sliced;
        _isLoading = false;
      });
    }
  }

  void _handleSubmit() async {
    if (_currentScenarioIndex < _activeScenarios.length - 1) {
      setState(() {
        _currentScenarioIndex++;
        _currentSliderValue = 1.0;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final gameKey = 'howMad';
      int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
      await prefs.setInt('vault_index_$gameKey', vaultIndex + 10);
      
      int sessionsToday = prefs.getInt('sessions_played_today_$gameKey') ?? 0;
      await prefs.setInt('sessions_played_today_$gameKey', sessionsToday + 1);
      await prefs.setInt('last_session_timestamp_$gameKey', DateTime.now().millisecondsSinceEpoch);

      if (mounted) {
        context.read<AppState>().addGamePoints(15, isUser: true);
      }
      
      _showResultsOverlay();
    }
  }

  void _showResultsOverlay() async {
    final currentAppState = context.read<AppState>();
    if (currentAppState.currentCoupleId != null && currentAppState.currentUid != null) {
      await FirebaseGateService.recordGameSession('How Mad?', currentAppState.currentCoupleId!, currentAppState.currentUid!);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (dialogContext) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🔥", style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      "Scale Complete!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4A90E2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Awesome! You earned 15 points.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    BouncingButton(
                      onTap: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context); // Close screen
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF8FD3F4), Color(0xFF84FAB0)]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "Return to Dashboard",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showToast(String message, Color color) {
          showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GameSkeletonLoader();
    }
    
    if (_isLocked && _unlockTime != null) {
      return PremiumLockScreen(
        isDailyLimit: _isDailyLock,
        unlockTime: _unlockTime!,
      );
    }
    final currentQ = _activeScenarios[_currentScenarioIndex];
    final String scenarioText = currentQ["scenario"];

    String emoji = "😌";
    Color sliderColor = const Color(0xFFA8E6CF); 
    
    if (_currentSliderValue > 7) {
      emoji = "😡";
      sliderColor = const Color(0xFFFF8B94); 
    } else if (_currentSliderValue > 4) {
      emoji = "🤔";
      sliderColor = const Color(0xFFFFD3B6); 
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "How Mad?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [],
      ),
      body: DynamicBackground(
        colors: const [Color(0xFFFF9A9E), Color(0xFFFECFEF)], // Pink/Purple
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Scenario ${_currentScenarioIndex + 1}/${_activeScenarios.length}",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Rate It",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Question Card
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey<int>(_currentScenarioIndex),
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
                        ],
                      ),
                      child: Center(
                        child: Text(
                          scenarioText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  // Slider UI
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${_currentSliderValue.round()} / 10",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                            ]
                          ),
                        ),
                        const SizedBox(height: 10),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: sliderColor,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: sliderColor,
                            overlayColor: Colors.white.withOpacity(0.2),
                            trackHeight: 8.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                          ),
                          child: Slider(
                            value: _currentSliderValue,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (value) {
                              setState(() {
                                _currentSliderValue = value;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: Text("Totally Fine 😌", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 16),
                              Flexible(child: Text("Absolutely Not 😡", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  // Submit Button
                  BouncingButton(
                    onTap: _handleSubmit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFFD3B6)]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF9A9E).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Text(
                        "Next Scenario",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

