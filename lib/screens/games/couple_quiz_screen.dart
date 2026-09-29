import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../widgets/glass_container.dart';
import '../../widgets/bouncing_button.dart';

enum QuizState {
  voting,
  reveal
}

class QuizPrompt {
  final String text;
  QuizPrompt(this.text);
}

class CoupleQuizScreen extends StatefulWidget {
  const CoupleQuizScreen({super.key});

  @override
  State<CoupleQuizScreen> createState() => _CoupleQuizScreenState();
}

class _CoupleQuizScreenState extends State<CoupleQuizScreen> {
  // Hardcoded classic viral questions
  final List<QuizPrompt> _prompts = [
    QuizPrompt("Who takes longer to get ready?"),
    QuizPrompt("Who said 'I love you' first?"),
    QuizPrompt("Who is more likely to survive a zombie apocalypse?"),
    QuizPrompt("Who has the better fashion sense?"),
    QuizPrompt("Who is the better cook?"),
    QuizPrompt("Who is more likely to start an argument over nothing?"),
    QuizPrompt("Who falls asleep during movies more often?"),
    QuizPrompt("Who spends more money on random things?"),
    QuizPrompt("Who is more romantic?"),
    QuizPrompt("Who is the better driver?"),
  ];

  int _currentIndex = 0;
  int _matches = 0;
  
  QuizState _currentState = QuizState.voting;
  
  // Votes: "Me" or "Partner"
  String? _voteP1; // Bottom Player (You)
  String? _voteP2; // Top Player (Partner)
  
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _prompts.shuffle();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleVote(bool isPlayer1, String choice) {
    if (_currentState == QuizState.reveal) return;

    setState(() {
      if (isPlayer1) {
        _voteP1 = choice;
      } else {
        _voteP2 = choice;
      }

      // If both have voted, reveal!
      if (_voteP1 != null && _voteP2 != null) {
        _currentState = QuizState.reveal;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    // Both picked the SAME person! 
    // If P1 picked "Me" (P1) and P2 picked "Partner" (P1) -> Match
    // If P1 picked "Partner" (P2) and P2 picked "Me" (P2) -> Match
    
    bool isMatch = false;
    if (_voteP1 == "Me" && _voteP2 == "Partner") isMatch = true;
    if (_voteP1 == "Partner" && _voteP2 == "Me") isMatch = true;
    
    if (isMatch) {
      setState(() {
        _matches++;
      });
      _confettiController.play();
    }
  }

  void _nextPrompt() {
    setState(() {
      if (_currentIndex < _prompts.length - 1) {
        _currentIndex++;
      } else {
        _prompts.shuffle();
        _currentIndex = 0;
        _matches = 0; // Reset score if looping
      }
      _currentState = QuizState.voting;
      _voteP1 = null;
      _voteP2 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _prompts[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Dark theme
      body: Stack(
        children: [
          Column(
            children: [
              // Top Player (Partner)
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _buildPlayerHalf(
                    isPlayer1: false,
                    vote: _voteP2,
                    otherVote: _voteP1,
                  ),
                ),
              ),
              
              Container(height: 2, color: Colors.white24),
              
              // Bottom Player (You)
              Expanded(
                child: _buildPlayerHalf(
                  isPlayer1: true,
                  vote: _voteP1,
                  otherVote: _voteP2,
                ),
              ),
            ],
          ),
          
          // Confetti Overlay
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 40,
              minBlastForce: 20,
              emissionFrequency: 0.1,
              numberOfParticles: 30,
              colors: const [Color(0xFFC084FC), Color(0xFF4ECDC4), Color(0xFFFF6B6B)],
            ),
          ),
          
          // Center Prompt Banner
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A40).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFC084FC).withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFC084FC).withOpacity(0.3), blurRadius: 20)
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Matches: $_matches",
                    style: GoogleFonts.poppins(color: const Color(0xFFC084FC), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prompt.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_currentState == QuizState.reveal) ...[
                    const SizedBox(height: 20),
                    BouncingButton(
                      onTap: _nextPrompt,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC084FC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Next Question",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            left: 20,
            top: MediaQuery.of(context).size.height / 2 - 24,
            child: FloatingActionButton(
              heroTag: "back",
              mini: true,
              backgroundColor: Colors.black45,
              elevation: 0,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlayerHalf({
    required bool isPlayer1,
    required String? vote,
    required String? otherVote,
  }) {
    bool isMatch = false;
    if (_currentState == QuizState.reveal) {
      if (_voteP1 == "Me" && _voteP2 == "Partner") isMatch = true;
      if (_voteP1 == "Partner" && _voteP2 == "Me") isMatch = true;
    }

    return Container(
      padding: const EdgeInsets.all(30),
      color: _currentState == QuizState.reveal 
          ? (isMatch ? const Color(0xFF4ECDC4).withOpacity(0.1) : const Color(0xFFFF6B6B).withOpacity(0.1))
          : Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end, // Push content away from the center prompt
        children: [
          if (_currentState == QuizState.reveal) ...[
            Text(
              isMatch ? "WE AGREE! 🥂" : "WE DISAGREE! 🙅‍♀️",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isMatch ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B)
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You voted:",
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            Text(
              vote == "Me" ? "ME" : "MY PARTNER",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: vote == "Me" ? const Color(0xFFC084FC) : const Color(0xFFFFD93D)
              ),
            ),
            const Spacer(),
          ] else ...[
            Text(
              vote != null ? "Waiting for partner..." : "Cast your vote secretly!",
              style: GoogleFonts.poppins(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildVoteButton(
                  label: "ME",
                  color: const Color(0xFFC084FC),
                  isSelected: vote == "Me",
                  isLocked: vote != null,
                  onTap: () => _handleVote(isPlayer1, "Me"),
                ),
                _buildVoteButton(
                  label: "PARTNER",
                  color: const Color(0xFFFFD93D),
                  isSelected: vote == "Partner",
                  isLocked: vote != null,
                  onTap: () => _handleVote(isPlayer1, "Partner"),
                ),
              ],
            ),
            const SizedBox(height: 50), // Padding from bottom edge
          ],
        ],
      ),
    );
  }

  Widget _buildVoteButton({
    required String label,
    required Color color,
    required bool isSelected,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    // If a vote is locked in and this button WAS NOT selected, dim it drastically
    bool isDimmed = isLocked && !isSelected;

    return BouncingButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDimmed ? Colors.black26 : (isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDimmed ? Colors.transparent : color,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 15)] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDimmed ? Colors.white24 : Colors.white,
          ),
        ),
      ),
    );
  }
}

