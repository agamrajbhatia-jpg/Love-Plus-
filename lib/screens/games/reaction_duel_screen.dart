import 'dart:math';
import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

enum DuelState {
  waitingToStart,
  waitingForGreen,
  go,
  roundOver,
  gameOver
}

class ReactionDuelScreen extends StatefulWidget {
  const ReactionDuelScreen({super.key});

  @override
  State<ReactionDuelScreen> createState() => _ReactionDuelScreenState();
}

class _ReactionDuelScreenState extends State<ReactionDuelScreen> {
  DuelState _currentState = DuelState.waitingToStart;
  Timer? _delayTimer;
  
  int _scoreP1 = 0; // Bottom player (You)
  int _scoreP2 = 0; // Top player (Partner)
  
  String _messageP1 = "Tap to Start!";
  String _messageP2 = "Tap to Start!";
  
  Color _colorP1 = const Color(0xFF1E1E2C);
  Color _colorP2 = const Color(0xFF1E1E2C);
  
  final int _winningScore = 5;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startRound() {
    setState(() {
      _currentState = DuelState.waitingForGreen;
      _messageP1 = "Wait for it...";
      _messageP2 = "Wait for it...";
      _colorP1 = const Color(0xFFFF3B30); // Red
      _colorP2 = const Color(0xFFFF3B30);
    });

    final int delay = Random().nextInt(4000) + 2000; // 2 to 6 seconds
    _delayTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted && _currentState == DuelState.waitingForGreen) {
        setState(() {
          _currentState = DuelState.go;
          _messageP1 = "TAP!";
          _messageP2 = "TAP!";
          _colorP1 = const Color(0xFF34C759); // Green
          _colorP2 = const Color(0xFF34C759);
        });
      }
    });
  }

  void _handleTap(bool isPlayer1) {
    if (_currentState == DuelState.waitingToStart || _currentState == DuelState.roundOver) {
      if (_currentState != DuelState.gameOver) {
        _startRound();
      }
      return;
    }

    if (_currentState == DuelState.waitingForGreen) {
      // False start!
      _delayTimer?.cancel();
      setState(() {
        _currentState = DuelState.roundOver;
        if (isPlayer1) {
          _scoreP2++;
          _messageP1 = "False Start!";
          _messageP2 = "Point for you!";
          _colorP1 = Colors.grey.shade900;
          _colorP2 = const Color(0xFF4ECDC4);
        } else {
          _scoreP1++;
          _messageP2 = "False Start!";
          _messageP1 = "Point for you!";
          _colorP2 = Colors.grey.shade900;
          _colorP1 = const Color(0xFFFF6B6B);
        }
      });
    } else if (_currentState == DuelState.go) {
      // Legit tap!
      setState(() {
        _currentState = DuelState.roundOver;
        if (isPlayer1) {
          _scoreP1++;
          _messageP1 = "Winner! +1";
          _messageP2 = "Too Slow!";
          _colorP1 = const Color(0xFFFF6B6B);
          _colorP2 = Colors.grey.shade900;
        } else {
          _scoreP2++;
          _messageP2 = "Winner! +1";
          _messageP1 = "Too Slow!";
          _colorP2 = const Color(0xFF4ECDC4);
          _colorP1 = Colors.grey.shade900;
        }
      });
    }

    _checkGameOver();
  }

  void _checkGameOver() {
    if (_scoreP1 >= _winningScore || _scoreP2 >= _winningScore) {
      setState(() {
        _currentState = DuelState.gameOver;
        if (_scoreP1 >= _winningScore) {
          _messageP1 = "YOU WON THE DUEL! 🏆";
          _messageP2 = "YOU LOST! 😭";
        } else {
          _messageP2 = "YOU WON THE DUEL! 🏆";
          _messageP1 = "YOU LOST! 😭";
        }
        _colorP1 = _scoreP1 >= _winningScore ? const Color(0xFFFFD93D) : Colors.grey.shade900;
        _colorP2 = _scoreP2 >= _winningScore ? const Color(0xFFFFD93D) : Colors.grey.shade900;
      });
      _confettiController.play();
    }
  }

  void _restartGame() {
    setState(() {
      _scoreP1 = 0;
      _scoreP2 = 0;
      _currentState = DuelState.waitingToStart;
      _messageP1 = "Tap to Start!";
      _messageP2 = "Tap to Start!";
      _colorP1 = const Color(0xFF1E1E2C);
      _colorP2 = const Color(0xFF1E1E2C);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Top Player (Partner)
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2, // Rotate 180 degrees
                  child: _buildPlayerHalf(
                    isPlayer1: false,
                    color: _colorP2,
                    message: _messageP2,
                    score: _scoreP2,
                    onTap: () => _handleTap(false),
                  ),
                ),
              ),
              
              // Divider
              Container(height: 4, color: Colors.black),
              
              // Bottom Player (You)
              Expanded(
                child: _buildPlayerHalf(
                  isPlayer1: true,
                  color: _colorP1,
                  message: _messageP1,
                  score: _scoreP1,
                  onTap: () => _handleTap(true),
                ),
              ),
            ],
          ),
          
          // Confetti for Winner
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 100, 
              minBlastForce: 80, 
              emissionFrequency: 0.05,
              numberOfParticles: 50, 
              gravity: 0.1,
              colors: const [
                Color(0xFFFF6B6B), 
                Color(0xFF4ECDC4), 
                Color(0xFFFFD93D),
              ],
            ),
          ),
          
          // Back Button / Restart Button
          Positioned(
            left: 20,
            top: MediaQuery.of(context).size.height / 2 - 24,
            child: Row(
              children: [
                FloatingActionButton(
                  heroTag: "back",
                  mini: true,
                  backgroundColor: Colors.white24,
                  elevation: 0,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                if (_currentState == DuelState.gameOver) ...[
                  const SizedBox(width: 10),
                  FloatingActionButton.extended(
                    heroTag: "restart",
                    backgroundColor: Colors.white24,
                    elevation: 0,
                    onPressed: _restartGame,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Rematch", style: TextStyle(color: Colors.white)),
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlayerHalf({
    required bool isPlayer1,
    required Color color,
    required String message,
    required int score,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Score: $score / $_winningScore",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  if (_currentState == DuelState.go)
                    const Shadow(color: Colors.white, blurRadius: 20)
                ]
              ),
            ),
            if (_currentState == DuelState.roundOver || _currentState == DuelState.waitingToStart) ...[
               const SizedBox(height: 30),
               Text(
                 "(Tap to continue)",
                 style: GoogleFonts.poppins(color: Colors.white38),
               )
            ]
          ],
        ),
      ),
    );
  }
}

