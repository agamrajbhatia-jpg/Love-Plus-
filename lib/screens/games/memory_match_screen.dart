import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import '../../widgets/glass_container.dart';
import '../../widgets/bouncing_button.dart';
import '../../widgets/dynamic_background.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  // Game Logic
  final List<String> _emojiPairs = ['💌', '🌹', '🥂', '📸', '💍', '🧸', '✈️', '💖'];
  late List<String> _cards;
  late List<bool> _cardFlipped;
  late List<bool> _cardMatched;
  
  int _scoreP1 = 0;
  int _scoreP2 = 0;
  bool _isPlayer1Turn = true; // P1 = Pink, P2 = Teal
  
  int? _firstFlippedIndex;
  bool _isAnimating = false;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initializeGame();
  }

  void _initializeGame() {
    _cards = [..._emojiPairs, ..._emojiPairs];
    _cards.shuffle(Random());
    _cardFlipped = List.filled(16, false);
    _cardMatched = List.filled(16, false);
    _scoreP1 = 0;
    _scoreP2 = 0;
    _isPlayer1Turn = true;
    _firstFlippedIndex = null;
    _isAnimating = false;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onCardTap(int index) async {
    if (_isAnimating || _cardFlipped[index] || _cardMatched[index]) return;

    setState(() {
      _cardFlipped[index] = true;
    });

    if (_firstFlippedIndex == null) {
      // First card flipped
      _firstFlippedIndex = index;
    } else {
      // Second card flipped
      _isAnimating = true;
      int firstIndex = _firstFlippedIndex!;
      _firstFlippedIndex = null;

      if (_cards[firstIndex] == _cards[index]) {
        // Match!
        setState(() {
          _cardMatched[firstIndex] = true;
          _cardMatched[index] = true;
          if (_isPlayer1Turn) {
            _scoreP1++;
          } else {
            _scoreP2++;
          }
        });
        _checkWinCondition();
        _isAnimating = false;
      } else {
        // No match, flip back after delay
        await Future.delayed(const Duration(milliseconds: 1000));
        setState(() {
          _cardFlipped[firstIndex] = false;
          _cardFlipped[index] = false;
          _isPlayer1Turn = !_isPlayer1Turn; // Switch turns on fail
        });
        _isAnimating = false;
      }
    }
  }

  void _checkWinCondition() {
    if (_cardMatched.every((matched) => matched)) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGameOver = _cardMatched.every((matched) => matched);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Memory Match",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Dynamic Background
          const Positioned.fill(
            child: DynamicBackground(
              colors: [
                Color(0xFF1E1E2C), 
                Color(0xFF2A2A40),
                Color(0xFF11111A)
              ],
              child: SizedBox.expand(),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // Score Board
                _buildScoreBoard(),
                
                const SizedBox(height: 30),
                
                // Game Board
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8, // Taller cards
                      ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        return _buildCard(index);
                      },
                    ),
                  ),
                ),
                
                // Restart Button (Only when game over)
                if (isGameOver)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: BouncingButton(
                      onTap: () {
                        setState(() {
                          _initializeGame();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC084FC), Color(0xFF4ECDC4)],
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFC084FC).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))
                          ]
                        ),
                        child: Text(
                          "Play Again",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // point downwards
              maxBlastForce: 5, 
              minBlastForce: 2, 
              emissionFrequency: 0.05,
              numberOfParticles: 50, 
              gravity: 0.2,
              colors: const [
                Color(0xFFFF6B6B), 
                Color(0xFF4ECDC4), 
                Color(0xFFC084FC),
                Colors.pinkAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    final bool isGameOver = _cardMatched.every((matched) => matched);
    
    String statusText;
    Color statusColor;

    if (isGameOver) {
      if (_scoreP1 > _scoreP2) {
        statusText = "You Win! 🏆";
        statusColor = const Color(0xFFFF6B6B);
      } else if (_scoreP2 > _scoreP1) {
        statusText = "Partner Wins! 🏆";
        statusColor = const Color(0xFF4ECDC4);
      } else {
        statusText = "It's a Tie! 🤝";
        statusColor = Colors.white;
      }
    } else {
      statusText = _isPlayer1Turn ? "Your Turn" : "Partner's Turn";
      statusColor = _isPlayer1Turn ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GlassContainer(
        blur: 15,
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  shadows: [Shadow(color: statusColor, blurRadius: 10)]
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ScoreBadge(label: "You", score: _scoreP1, color: const Color(0xFFFF6B6B), isActive: _isPlayer1Turn && !isGameOver),
                  _ScoreBadge(label: "Partner", score: _scoreP2, color: const Color(0xFF4ECDC4), isActive: !_isPlayer1Turn && !isGameOver),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    bool isFlipped = _cardFlipped[index];
    bool isMatched = _cardMatched[index];

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: isFlipped ? 1 : 0),
        duration: const Duration(milliseconds: 400),
        builder: (context, double value, child) {
          // Matrix 3D flip effect
          final angle = value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle);

          // Once rotated past 90 degrees (pi/2), we show the face of the card
          final bool isFaceUp = value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: isFaceUp 
                // Front of Card (Flipped over, mirror Y so it doesn't render backwards)
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isMatched ? Colors.white.withOpacity(0.2) : const Color(0xFF2A2A40),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMatched ? const Color(0xFFC084FC) : Colors.white.withOpacity(0.3),
                          width: isMatched ? 2 : 1,
                        ),
                        boxShadow: isMatched 
                            ? [const BoxShadow(color: Color(0x66C084FC), blurRadius: 10)] 
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          _cards[index],
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  )
                // Back of Card (Face down)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF1493).withOpacity(0.8),
                          const Color(0xFFC084FC).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(2, 2))
                      ]
                    ),
                    child: const Center(
                      child: Icon(Icons.favorite, color: Colors.white54, size: 24),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool isActive;

  const _ScoreBadge({
    required this.label,
    required this.score,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : Colors.white.withOpacity(0.1),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          Text(
            score.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
