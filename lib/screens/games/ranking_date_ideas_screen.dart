import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/point_service.dart';
import '../../services/firebase_gate_service.dart';
import '../../providers/app_state.dart';
import '../../widgets/bouncing_button.dart';
import '../../widgets/dynamic_background.dart';
import '../../widgets/game_skeleton_loader.dart';
import '../../data/library_vault.dart';
import '../../widgets/premium_lock_screen.dart';

class RankingDateIdeasScreen extends StatefulWidget {
  final String? coupleId;
  final String? currentUserId;

  const RankingDateIdeasScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  State<RankingDateIdeasScreen> createState() => _RankingDateIdeasScreenState();
}

class _RankingDateIdeasScreenState extends State<RankingDateIdeasScreen> {
  bool _isLoading = true;
  bool _isLocked = false;
  bool _isDailyLock = false;
  DateTime? _unlockTime;

  int _currentItemIndex = 0;
  List<String> _items = [];
  List<String?> _myRankings = [null, null, null, null, null];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    final gameKey = 'blindRanking';
    
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

    final vaultList = LibraryVault.games['Blind Ranking Date Ideas']!;
    int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
    
    List<String> sliced = [];
    for (int i = 0; i < 5; i++) {
      sliced.add(vaultList[(vaultIndex + i) % vaultList.length]);
    }

    if (mounted) {
      setState(() {
        _items = sliced;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final gameKey = 'blindRanking';
    int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
    await prefs.setInt('vault_index_$gameKey', vaultIndex + 5);
    
    int sessionsToday = prefs.getInt('sessions_played_today_$gameKey') ?? 0;
    await prefs.setInt('sessions_played_today_$gameKey', sessionsToday + 1);
    await prefs.setInt('last_session_timestamp_$gameKey', DateTime.now().millisecondsSinceEpoch);

    if (mounted) {
      context.read<AppState>().addGamePoints(15, isUser: true);
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
                    const Text("🏆", style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      "Ranking Complete!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF6A1B9A),
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
                      onTap: () async {
                        final coupleId = context.read<AppState>().currentCoupleId;
                        if (coupleId != null) {
                          FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('shared_games').doc('date_ranking').set({
                            'last_completed_by': context.read<AppState>().currentUid,
                            'timestamp': FieldValue.serverTimestamp(),
                            'ranking': _myRankings,
                          }, SetOptions(merge: true));
                          
                          final uid = context.read<AppState>().currentUid;
                          if (uid != null) {
                            await FirebaseGateService.recordGameSession('Ranking Date Ideas', coupleId, uid);
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Sent to partner! 💕", style: GoogleFonts.poppins(color: Colors.white)),
                              backgroundColor: const Color(0xFF6A1B9A),
                            )
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "Send to Partner 🚀",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
    final bool isDone = _currentItemIndex >= _items.length;
    final currentItem = isDone ? "All Done!" : _items[_currentItemIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Blind Ranking",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: DynamicBackground(
        colors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  isDone ? "Your Final Ranking" : "Rank this Idea:",
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Container(
                    key: ValueKey<String>(currentItem),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Text(
                      currentItem,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: List.generate(5, (index) {
                      final rankedItem = _myRankings[index];
                      final isEmpty = rankedItem == null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: BouncingButton(
                          onTap: () {
                            if (!isEmpty || isDone) return;
                            
                            setState(() {
                              _myRankings[index] = currentItem;
                              _currentItemIndex++;
                            });

                            if (_currentItemIndex == 5) {
                              _handleComplete();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: isEmpty ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: isEmpty ? Border.all(color: Colors.white54, width: 2) : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isEmpty ? Colors.white30 : const Color(0xFF6A1B9A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${index + 1}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    isEmpty ? "Tap to place here" : rankedItem,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
                                      color: isEmpty ? Colors.white70 : const Color(0xFF6A1B9A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

