import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../providers/app_state.dart';
import '../../widgets/bouncing_button.dart';
import '../../widgets/dynamic_background.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_gate_service.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/library_vault.dart';
import '../../widgets/premium_lock_screen.dart';

import '../../widgets/game_skeleton_loader.dart';

class WouldYouRatherScreen extends StatefulWidget {
  final List<String>? customQuestions;
  final String? customDeckId;
  const WouldYouRatherScreen({super.key, this.customQuestions, this.customDeckId});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  int _currentQuestionIndex = 0;
  List<Map<String, String>> _questions = [];
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
    if (widget.customQuestions != null) {
      _loadCustomQuestions();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    final gameKey = 'wouldYouRather';
    
    final lastDate = prefs.getString('last_played_date_$gameKey');
    int sessionsToday = prefs.getInt('sessions_played_today_$gameKey') ?? 0;
    
    if (lastDate != today) {
      sessionsToday = 0;
      await prefs.setString('last_played_date_$gameKey', today);
      await prefs.setInt('sessions_played_today_$gameKey', 0);
    }
    
    // if (user.isPremium) return true;
    
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

    final originalList = widget.customQuestions ?? LibraryVault.games['Would You Rather']!;
    List<String> vaultList = List.from(originalList);
    int itemsCount = widget.customQuestions != null ? vaultList.length : 10;
    
    if (widget.customQuestions == null) {
      final appState = Provider.of<AppState>(context, listen: false);
      final coupleId = appState.currentCoupleId ?? 'default';
      int seed = coupleId.hashCode ^ DateTime.now().day;
      if (coupleId != 'default') {
        seed = await FirebaseGateService.getDailySeed('Would You Rather', coupleId);
      }
      vaultList.shuffle(math.Random(seed));
      vaultList = vaultList.take(5).toList();
    }
    
    int actualCount = vaultList.length;
    List<Map<String, String>> sliced = [];
    for (int i = 0; i < actualCount; i++) {
      String q = vaultList[i];
      String stripped = q.replaceAll(RegExp(r'^would you rather\s+', caseSensitive: false), '').replaceAll('?', '');
      List<String> parts = stripped.split(RegExp(r'\s+or\s+', caseSensitive: false));
      
      String optA = parts.isNotEmpty ? parts.first.trim() : "Option A";
      // Capitalize first letter of option A
      if (optA.isNotEmpty) optA = optA[0].toUpperCase() + optA.substring(1);
      
      String optB = parts.length > 1 ? parts.sublist(1).join(' or ').trim() : "Option B";
      // Capitalize first letter of option B
      if (optB.isNotEmpty) optB = optB[0].toUpperCase() + optB.substring(1);

      sliced.add({
        "question": q,
        "optionA": optA,
        "optionB": optB,
      });
    }

    if (mounted) {
      setState(() {
        _questions = sliced;
        _isLoading = false;
      });
    }
  }

  void _loadCustomQuestions() {
    List<Map<String, String>> sliced = [];
    for (String q in widget.customQuestions!) {
      String stripped = q.replaceAll(RegExp(r'^would you rather\s+', caseSensitive: false), '').replaceAll('?', '');
      List<String> parts = stripped.split(RegExp(r'\s+or\s+', caseSensitive: false));
      
      String optA = parts.isNotEmpty ? parts.first.trim() : "Option A";
      if (optA.isNotEmpty) optA = optA[0].toUpperCase() + optA.substring(1);
      
      String optB = parts.length > 1 ? parts.sublist(1).join(' or ').trim() : "Option B";
      if (optB.isNotEmpty) optB = optB[0].toUpperCase() + optB.substring(1);

      sliced.add({
        "question": q,
        "optionA": optA,
        "optionB": optB,
      });
    }
    if (mounted) {
      setState(() {
        _questions = sliced;
        _isLoading = false;
      });
    }
  }
  void _handleChoice(String choice, BuildContext context) async {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      if (widget.customDeckId != null) {
        final coupleId = context.read<AppState>().currentCoupleId;
        if (coupleId != null) {
          FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('custom_decks').doc(widget.customDeckId).update({'isPlayed': true});
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final gameKey = 'wouldYouRather';
        int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
        await prefs.setInt('vault_index_$gameKey', vaultIndex + 10);
        
        int sessionsToday = prefs.getInt('sessions_played_today_$gameKey') ?? 0;
        await prefs.setInt('sessions_played_today_$gameKey', sessionsToday + 1);
        await prefs.setInt('last_session_timestamp_$gameKey', DateTime.now().millisecondsSinceEpoch);
      }

      // End of round scoring: +15 points globally
      if (mounted) {
        context.read<AppState>().addGamePoints(15, isUser: true);
      }


      // Show smooth game-complete toast overlay constrained within SafeArea
            final currentAppState = context.read<AppState>();
      if (currentAppState.currentCoupleId != null && currentAppState.currentUid != null) {
        await FirebaseGateService.recordGameSession('Would You Rather', currentAppState.currentCoupleId!, currentAppState.currentUid!);
      }
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
                      color: const Color(0xFFFF6B6B).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Text(
                      "Game Complete! +15 ❤️",
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

      // Auto-dismiss dialog and screen after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context); // Pop dialog
          Navigator.pop(context); // Pop game screen
        }
      });
    }
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
    final currentQ = _questions[_currentQuestionIndex];
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Would You Rather?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [],
      ),
      body: DynamicBackground(
        colors: const [Color(0xFFff9a9e), Color(0xFFfecfef)],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              key: ValueKey<int>(_currentQuestionIndex),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Would you rather...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
                      ]
                    ),
                  ),
                  const SizedBox(height: 50),
                  Expanded(
                    child: BouncingButton(
                      onTap: () => _handleChoice('A', context),
                      child: _ChoiceCard(
                        text: currentQ["optionA"]!,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "OR",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: BouncingButton(
                      onTap: () => _handleChoice('B', context),
                      child: _ChoiceCard(
                        text: currentQ["optionB"]!,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff0844), Color(0xFFffb199)],
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

class _ChoiceCard extends StatelessWidget {
  final String text;
  final LinearGradient gradient;

  const _ChoiceCard({required this.text, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}



