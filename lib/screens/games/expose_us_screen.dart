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

class ExposeUsScreen extends StatefulWidget {
  const ExposeUsScreen({super.key});

  @override
  State<ExposeUsScreen> createState() => _ExposeUsScreenState();
}

class _ExposeUsScreenState extends State<ExposeUsScreen> {
  int _currentIndex = 0;
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
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    final gameKey = 'exposeUs';
    
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
      seed = await FirebaseGateService.getDailySeed('Expose Us', coupleId);
    }
    
    final vaultList = List<String>.from(LibraryVault.games['Expose Us']!);
    vaultList.shuffle(math.Random(seed));
    
    List<String> sliced = [];
    for (String item in vaultList.take(5)) {
      sliced.add(item);
    }

    if (mounted) {
      setState(() {
        _questions = sliced;
        _isLoading = false;
      });
    }
  }

  void _handleAnswer(String answer) async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final gameKey = 'exposeUs';
      int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
      await prefs.setInt('vault_index_$gameKey', vaultIndex + 10);
      
      int sessionsToday = prefs.getInt('sessions_played_today_$gameKey') ?? 0;
      await prefs.setInt('sessions_played_today_$gameKey', sessionsToday + 1);
      await prefs.setInt('last_session_timestamp_$gameKey', DateTime.now().millisecondsSinceEpoch);

      _showResultsOverlay();
    }
  }

  void _showResultsOverlay() async {
    final appState = context.read<AppState>();
    
    // Add points globally
    appState.addGamePoints(15, isUser: true);
    
    // Trigger Freemium lock
    appState.markExposeUsPlayed();

          final currentAppState = context.read<AppState>();
      if (currentAppState.currentCoupleId != null && currentAppState.currentUid != null) {
        await FirebaseGateService.recordGameSession('Expose Us', currentAppState.currentCoupleId!, currentAppState.currentUid!);
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
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "👀",
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Exposed!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFF8B94),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "The truth is out there.",
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
                          gradient: const LinearGradient(colors: [Color(0xFFFF8B94), Color(0xFFFFD3B6)]),
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
          "Expose Us!",
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
        colors: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)], // Muted purple to pink
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Question ${_currentIndex + 1}/${_questions.length}",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      key: ValueKey<int>(_currentIndex),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "👀",
                              style: TextStyle(fontSize: 60),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _questions[_currentIndex],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    BouncingButton(
                      onTap: () => _handleAnswer("Me"),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB)]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFA1C4FD).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Text(
                          "Me 🙋",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BouncingButton(
                      onTap: () => _handleAnswer("Partner"),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFFD3B6)]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFF9A9E).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Text(
                          "My Partner 🫵",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}


