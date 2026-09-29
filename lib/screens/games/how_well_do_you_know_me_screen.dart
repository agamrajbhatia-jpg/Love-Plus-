import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_gate_service.dart';
import 'dart:math' as math;
import '../../services/firebase_gate_service.dart';
import 'dart:math' as math;
import '../../data/library_vault.dart';
import '../../widgets/premium_lock_screen.dart';

import '../../providers/app_state.dart';
import '../../widgets/bouncing_button.dart';
import '../../widgets/dynamic_background.dart';
import '../../widgets/game_skeleton_loader.dart';

class HowWellDoYouKnowMeScreen extends StatefulWidget {
  final Map<String, dynamic>? challengeToPlay;

  const HowWellDoYouKnowMeScreen({super.key, this.challengeToPlay});

  @override
  State<HowWellDoYouKnowMeScreen> createState() => _HowWellDoYouKnowMeScreenState();
}

class _HowWellDoYouKnowMeScreenState extends State<HowWellDoYouKnowMeScreen> {
  int _currentQuestionIndex = 0;
  List<String> _questions = [];
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
    final appState = Provider.of<AppState>(context, listen: false);
    final coupleId = appState.currentCoupleId ?? 'default';
    int seed = coupleId.hashCode ^ DateTime.now().day;
    if (coupleId != 'default') {
      seed = await FirebaseGateService.getDailySeed('how_well_do_you_know_me', coupleId);
    }
    final vaultList = List<String>.from(LibraryVault.games['How Well Do You Know Me']!);
    vaultList.shuffle(math.Random(seed));
    
    List<String> sliced = vaultList.take(5).toList();

    if (mounted) {
      setState(() {
        _questions = sliced;
        _isLoading = false;
      });
    }
  }

  void _handleNext() async {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      if (mounted) {
        context.read<AppState>().addGamePoints(15, isUser: true);
      }
      
      final currentAppState = context.read<AppState>();
      if (currentAppState.currentCoupleId != null && currentAppState.currentUid != null) {
        await FirebaseGateService.recordGameSession('how_well_do_you_know_me', currentAppState.currentCoupleId!, currentAppState.currentUid!);
      }
      
      _showResultsOverlay();
    }
  }

  void _showResultsOverlay() {
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
                    const Text("✨", style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      "Quiz Complete!",
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
                        Navigator.pop(dialogContext);
                        Navigator.pop(context);
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

  Widget _buildGameMode() {
    final currentQ = _questions[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Q ${_currentQuestionIndex + 1}/10",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Discuss",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey<int>(_currentQuestionIndex),
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
              ],
            ),
            child: Center(
              child: Text(
                currentQ,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.3,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
                  ]
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 50),
        
        BouncingButton(
          onTap: _handleNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: const Color(0xFFA1C4FD).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Text(
              "Next Question",
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
    );
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "How Well Do You Know Me?",
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
        colors: const [Color(0xFFA1C4FD), Color(0xFFC2E9FB)], 
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: _buildGameMode(),
            ),
          ),
        ),
      ),
    );
  }
}



