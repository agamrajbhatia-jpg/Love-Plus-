import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../providers/app_state.dart';
import '../../data/game_vault.dart';
import '../../services/notification_service.dart';
import '../../services/point_service.dart';
import '../../services/firebase_gate_service.dart';

class LiveCardGameScreen extends StatefulWidget {
  final String deckName;
  final List<String>? customQuestions;
  final String? customDeckId;
  const LiveCardGameScreen({super.key, required this.deckName, this.customQuestions, this.customDeckId});

  @override
  State<LiveCardGameScreen> createState() => _LiveCardGameScreenState();
}

class _LiveCardGameScreenState extends State<LiveCardGameScreen> with SingleTickerProviderStateMixin {
  final CardSwiperController _controller = CardSwiperController();
  List<String> _questions = [];
  int _localIndex = 0;
  bool _isProgrammaticSwipe = false;
  bool _isLoading = true;
  Set<int> _viewedIndices = {};
  
  Timer? _cooldownTimer;
  Duration _cooldownRemaining = Duration.zero;
  bool _isCooldownActive = false;
  bool _isSyncing = false;
  bool _hasApiError = false;
  bool _isDailyLimitReached = false;
  String _apiErrorMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String get _deckKey => widget.deckName.toLowerCase().replaceAll(' ', '_');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _loadQuestions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinSession();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cooldownTimer?.cancel();
    _leaveSession();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (widget.customQuestions != null) {
      _questions = List.from(widget.customQuestions!);
    } else {
      final vaultDeck = List<String>.from(GameVault.decks[widget.deckName] ?? GameVault.decks['Icebreakers & Fun']!);
      
      // Deterministic random selection based on day ^ coupleId ^ maxPlayCount
      final coupleId = appState.currentCoupleId ?? 'default';
      
      int seed = coupleId.hashCode ^ DateTime.now().day;
      if (coupleId != 'default') {
        seed = await FirebaseGateService.getDailySeed(widget.deckName, coupleId);
      }
      
      final randomSeed = math.Random(seed);
      vaultDeck.shuffle(randomSeed);
      
      // Always take the first 10 questions for the day
      _questions = vaultDeck.take(5).toList();
    }
    
    final coupleId = appState.currentCoupleId ?? 'default';
    final prefs = await SharedPreferences.getInstance();
    final safeName = FirebaseGateService.getSafeGameName(widget.deckName);
    final savedIndex = prefs.getInt('${coupleId}_${safeName}_progress');
    if (savedIndex != null && savedIndex < _questions.length) {
      _localIndex = savedIndex;
      // Mark preceding indices as viewed so the completion check is accurate
      for (int i = 0; i < savedIndex; i++) {
        _viewedIndices.add(i);
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCooldownTimer(DateTime unlockTime) {
    if (!_isCooldownActive) {
      HapticFeedback.heavyImpact();
    }
    _isCooldownActive = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      if (now.isAfter(unlockTime)) {
        timer.cancel();
        // Keep _isCooldownActive true if we want the user to click the unlock button manually
        if (mounted) {
          setState(() {
            _cooldownRemaining = Duration.zero;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cooldownRemaining = unlockTime.difference(now);
          });
        }
      }
    });
    if (mounted) {
      setState(() {
        _cooldownRemaining = unlockTime.difference(DateTime.now());
      });
    }
  }

  Future<void> _handleDeckCompletion() async {
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    
    if (coupleId != null && uid != null) {
      if (widget.customDeckId != null) {
        await FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('custom_decks').doc(widget.customDeckId).update({'isPlayed': true});
      }
      await FirebaseGateService.recordGameSession(widget.deckName, coupleId, uid);
      final prefs = await SharedPreferences.getInstance();
      final safeName = FirebaseGateService.getSafeGameName(widget.deckName);
      await prefs.remove('${coupleId}_${safeName}_progress');
    }

    // Award points
    await PointService.awardPoints(context, 10);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deck Completed! +10 Couple Points! ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00FFD1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchNextVaultDeck() async {
    if (!mounted) return;
    setState(() {
      _isSyncing = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_deckKey}_unlock_time');
    _localIndex = 0;
    _viewedIndices.clear();
    
    await _loadQuestions();
    
    if (mounted) {
      final appState = context.read<AppState>();
      final coupleId = appState.currentCoupleId;
      if (coupleId != null) {
        FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('live_game_session').doc(FirebaseGateService.getSafeGameName(widget.deckName)).update({
          'current_card_index': 0,
        });
      }
      setState(() {
        _isSyncing = false;
        _isCooldownActive = false;
      });
    }
  }

  Future<void> _joinSession() async {
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    if (coupleId == null || uid == null) return;
    
    final docRef = FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('live_game_session').doc(FirebaseGateService.getSafeGameName(widget.deckName));
    await docRef.set({
      'active_deck_name': widget.deckName,
      'players_present': FieldValue.arrayUnion([uid]),
      'current_card_index': _localIndex,
    }, SetOptions(merge: true));
  }

  String? _cachedCoupleId;
  String? _cachedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedCoupleId = context.read<AppState>().currentCoupleId;
    _cachedUid = context.read<AppState>().currentUid;
  }

  Future<void> _leaveSession() async {
    final coupleId = _cachedCoupleId;
    final uid = _cachedUid;
    if (coupleId == null || uid == null) return;
    
    final docRef = FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('live_game_session').doc(FirebaseGateService.getSafeGameName(widget.deckName));
    await docRef.set({
      'players_present': FieldValue.arrayRemove([uid]),
    }, SetOptions(merge: true));
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (_isProgrammaticSwipe) {
      _isProgrammaticSwipe = false;
      return true;
    }
    
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    
    _viewedIndices.add(previousIndex);
    
    if (_viewedIndices.length >= _questions.length) {
      _handleDeckCompletion();
      return false; // Stop swipe
    }
    
    if (coupleId != null && uid != null) {
      final newIndex = currentIndex ?? (previousIndex + 1);
      _localIndex = newIndex;
      FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('live_game_session').doc(FirebaseGateService.getSafeGameName(widget.deckName)).update({
        'current_card_index': newIndex,
        'last_swiped_by': uid,
      });

      // Save resume state
      final safeName = FirebaseGateService.getSafeGameName(widget.deckName);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('${coupleId}_${safeName}_progress', newIndex);
      });
    }
    return true;
  }
  
  Widget _buildCompletionCard() {
    bool isReady = _cooldownRemaining.inSeconds <= 0;
    String minutes = _cooldownRemaining.inMinutes.toString().padLeft(2, '0');
    String seconds = (_cooldownRemaining.inSeconds % 60).toString().padLeft(2, '0');

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2E93), Color(0xFF00F0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x66FF2E93), blurRadius: 28, spreadRadius: 2),
                BoxShadow(color: Color(0x6600F0FF), blurRadius: 28, spreadRadius: 2),
              ],
            ),
            padding: const EdgeInsets.all(2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xCC0D0B12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 1),
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: const Text("?", style: TextStyle(fontSize: 48)),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "? Chapter Complete",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: const [
                            Shadow(color: Color(0x80FF2E93), blurRadius: 18),
                            Shadow(color: Color(0x4000F0FF), blurRadius: 28),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "WAIT WHILE WE MAKE A NEW DECK OF CARD FOR YOU BOTH",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      if (_hasApiError)
                        InkWell(
                          onTap: () async {
                            if (_isSyncing) return;
                            HapticFeedback.lightImpact();
                            await _fetchNextVaultDeck();
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x2AFFFFFF),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.redAccent, width: 1),
                            ),
                            child: _isSyncing 
                              ? const SizedBox(
                                  width: 24, 
                                  height: 24, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : Text(
                                  "Failed: $_apiErrorMessage. Tap to retry.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        )
                      else if (_isSyncing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x2AFFFFFF),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.cyan, width: 1),
                            boxShadow: const [
                              BoxShadow(color: Color(0x3300F0FF), blurRadius: 10),
                            ],
                          ),
                          child: const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          ),
                        )
                      else if (isReady)
                        InkWell(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await _fetchNextVaultDeck();
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0x2AFFFFFF),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.cyan, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyan.withOpacity(0.3 * _pulseAnimation.value),
                                      blurRadius: 15 * _pulseAnimation.value,
                                      spreadRadius: 2 * _pulseAnimation.value,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "? Open New Deck ?",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x2AFFFFFF),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.cyan, width: 1),
                            boxShadow: const [
                              BoxShadow(color: Color(0x3300F0FF), blurRadius: 10),
                            ],
                          ),
                          child: Text(
                            "? New Deck Unlocks In: $minutes:$seconds",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text(
                              "Return to Game Library",
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
        ),
      ),
    );
  }

  Widget _buildBackground() {
    Color solidColor;
    Color glowColor;

    switch (_deckKey) {
      case 'icebreakers_&_fun':
        solidColor = const Color(0xFF0B0F19); // Matte Obsidian Slate
        glowColor = const Color(0xFF00FFFF).withOpacity(0.15); // soft cyan/azure
        break;
      case 'deep_dive_talk':
        solidColor = const Color(0xFF12081F); // Matte Midnight Violet
        glowColor = const Color(0xFF0000FF).withOpacity(0.15); // deep sapphire-indigo
        break;
      case 'spontaneous_date_ideas':
        solidColor = const Color(0xFF1C070F); // Matte Rich Velvet Crimson
        glowColor = const Color(0xFFE0115F).withOpacity(0.12); // soft ruby/wine glow
        break;
      case 'playful_challenges':
        solidColor = const Color(0xFF18081A); // Matte Dark Plum
        glowColor = const Color(0xFFFF00FF).withOpacity(0.15); // vibrant electric-magenta
        break;
      default:
        solidColor = const Color(0xFF0B0F19);
        glowColor = const Color(0xFF00FFFF).withOpacity(0.15);
    }

    return Stack(
      children: [
        Container(color: solidColor),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 1.5,
                height: MediaQuery.of(context).size.width * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor,
                      glowColor.withOpacity(0.0),
                    ],
                    stops: const [0.0, 1.0],
                    radius: 0.5 * _pulseAnimation.value,
                  ),
                ),
              ),
            );
          }
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: coupleId == null || uid == null || _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('live_game_session').doc(FirebaseGateService.getSafeGameName(widget.deckName)).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final int serverIndex = data['current_card_index'] ?? 0;
                    final String? lastSwipedBy = data['last_swiped_by'];
                    
                    if (serverIndex > _localIndex && lastSwipedBy != uid) {
                      _isProgrammaticSwipe = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _controller.swipe(CardSwiperDirection.right);
                        _localIndex = serverIndex;
                      });
                    }
                  }

                  final int displayIndex = _localIndex;

                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          widget.deckName, 
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Color(0x80FF2E93), blurRadius: 18),
                              Shadow(color: Color(0x4000F0FF), blurRadius: 28),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Share this deck with your partner or play on call together ??",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isCooldownActive && displayIndex < _questions.length)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(
                            "Card ${displayIndex + 1} of ${_questions.length}",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_isDailyLimitReached)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0, top: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.lock_clock, color: Colors.white70, size: 64),
                                        const SizedBox(height: 24),
                                        Text(
                                          'Daily Limit Reached',
                                          style: GoogleFonts.playfairDisplay(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Come back tomorrow for new cards! ?',
                                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0, top: 8.0),
                            child: _isCooldownActive
                            ? _buildCompletionCard()
                            : CardSwiper(
                                key: ValueKey(_questions.isNotEmpty ? _questions[0] : 'empty'),
                                controller: _controller,
                                cardsCount: _questions.length,
                                onSwipe: _onSwipe,
                                isLoop: false,
                                numberOfCardsDisplayed: 3,
                                initialIndex: displayIndex,
                                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                                  return _GameCardWidget(
                                    text: _questions[index], 
                                    percentX: percentThresholdX,
                                  );
                                },
                              ),
                        ),
                      ),
                    ],
                  );
                }
              ),
          ),
        ],
      ),
    );
  }
}

class _GameCardWidget extends StatelessWidget {
  final String text;
  final int percentX;

  const _GameCardWidget({required this.text, required this.percentX});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2E93), Color(0xFF00F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66FF2E93), blurRadius: 28, spreadRadius: 2),
          BoxShadow(color: Color(0x6600F0FF), blurRadius: 28, spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.all(2.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC0D0B12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                if (percentX > 0)
                  Positioned(
                    top: 40,
                    left: 30,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("NEXT", style: GoogleFonts.poppins(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ),
                if (percentX < 0)
                  Positioned(
                    top: 40,
                    right: 30,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("SKIP", style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ),
                  
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: AutoSizeText(
                      text,
                      textAlign: TextAlign.center,
                      minFontSize: 18,
                      maxFontSize: 28,
                      maxLines: 8,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.35,
                        shadows: const [Shadow(color: Colors.black26, blurRadius: 15)]
                      ),
                    ),
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



