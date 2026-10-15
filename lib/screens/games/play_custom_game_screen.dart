import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';

class PlayCustomGameScreen extends StatefulWidget {
  final String gameId;
  final Map<String, dynamic> data;

  const PlayCustomGameScreen({
    super.key,
    required this.gameId,
    required this.data,
  });

  @override
  State<PlayCustomGameScreen> createState() => _PlayCustomGameScreenState();
}

class _PlayCustomGameScreenState extends State<PlayCustomGameScreen> {
  int _currentIndex = 0;
  bool _isCompleted = false;
  late final List<String> _questions;
  late final String _title;
  late final String _type;

  @override
  void initState() {
    super.initState();
    _title = widget.data['title']?.toString() ?? 'Custom Game';
    _type = widget.data['type']?.toString() ?? 'couple_card';

    final rawQuestions = widget.data['questions'];
    if (rawQuestions is List) {
      _questions = rawQuestions.map((q) => q.toString()).where((q) => q.trim().isNotEmpty).toList();
    } else {
      _questions = [];
    }

    if (_questions.isEmpty) {
      _questions.add("Enjoy this special surprise from your partner! ❤️");
    }

    if (widget.data['status'] == 'completed') {
      _isCompleted = true;
    }
  }

  Future<void> _markAsCompleted() async {
    setState(() => _isCompleted = true);
    HapticFeedback.mediumImpact();
    try {
      final appState = context.read<AppState>();
      final coupleId = appState.currentCoupleId;
      if (coupleId != null) {
        await FirebaseFirestore.instance
            .collection('couples')
            .doc(coupleId)
            .collection('custom_games')
            .doc(widget.gameId)
            .update({'status': 'completed'});

        // Also update custom_decks if existing doc
        try {
          await FirebaseFirestore.instance
              .collection('couples')
              .doc(coupleId)
              .collection('custom_decks')
              .doc(widget.gameId)
              .update({'status': 'completed', 'isPlayed': true});
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Error updating custom game status: $e");
    }
  }

  void _nextCard() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _markAsCompleted();
      setState(() => _currentIndex = _questions.length); // Completion screen
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final partnerName = appState.effectivePartnerName;
    final isAtEnd = _currentIndex >= _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF090810),
      body: Stack(
        children: [
          // Ambient Glowing Background
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF2A6D).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF9B51E0).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Created by $partnerName ❤️",
                              style: GoogleFonts.poppins(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Text(
                          isAtEnd ? "Done" : "${_currentIndex + 1}/${_questions.length}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Center Card / Completion Screen
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: isAtEnd ? _buildCompletionView(partnerName) : _buildActiveCard(),
                ),

                const Spacer(),

                // Bottom Controls
                if (!isAtEnd)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Row(
                      children: [
                        if (_currentIndex > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 26),
                            onPressed: _prevCard,
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        GestureDetector(
                          onTap: _nextCard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF2A6D).withOpacity(0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentIndex == _questions.length - 1 ? "Finish 🎉" : "Next Card",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Center(
                            child: Text(
                              "Return to Game Zone",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard() {
    final question = _questions[_currentIndex];
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 340, maxHeight: 440),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFF2A6D).withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2A6D).withOpacity(0.2),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2A6D).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.4)),
                ),
                child: Text(
                  _type == 'quiz' ? 'QUIZ QUESTION' : 'COUPLE CARD',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF2A6D),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      question,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Swipe or tap Next to continue",
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionView(String partnerName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF00F0FF).withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withOpacity(0.2),
                blurRadius: 28,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🎉", style: TextStyle(fontSize: 54)),
              const SizedBox(height: 16),
              Text(
                "Deck Completed!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You explored all the cards $partnerName prepared for you. You two are closer than ever! ❤️",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF00F0FF), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _isCompleted ? "Status: Completed" : "Status: Exploring",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF00F0FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
