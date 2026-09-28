import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/bouncing_button.dart';
import '../../widgets/dynamic_background.dart';

class TicTacToeScreen extends StatefulWidget {
  final String? coupleId;
  final String? currentUserId;

  const TicTacToeScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_isValid()) {
      _joinOrCreateGame();
    }
  }

  bool _isValid() {
    return widget.coupleId != null && widget.coupleId!.isNotEmpty && 
           widget.currentUserId != null && widget.currentUserId!.isNotEmpty;
  }

  Future<void> _joinOrCreateGame() async {
    final docRef = FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('games').doc('tictactoe');
    
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists || (snapshot.data() != null && snapshot.data()!['status'] == 'finished')) {
          transaction.set(docRef, {
            'board': ['', '', '', '', '', '', '', '', ''],
            'player1': widget.currentUserId,
            'player2': '',
            'currentTurn': widget.currentUserId,
            'status': 'waiting',
            'winner': '',
          });
        } else {
          final data = snapshot.data()!;
          if (data['status'] == 'waiting' && data['player1'] != widget.currentUserId) {
            transaction.update(docRef, {
              'player2': widget.currentUserId,
              'status': 'playing',
            });
          }
        }
      });
    } catch (e) {
      debugPrint("Transaction failed: $e");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _restartGame() async {
    if (!_isValid()) return;
    
    final docRef = FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('games').doc('tictactoe');
    await docRef.set({
      'board': ['', '', '', '', '', '', '', '', ''],
      'player1': widget.currentUserId,
      'player2': '',
      'currentTurn': widget.currentUserId,
      'status': 'waiting',
      'winner': '',
    });
  }

  String _checkWin(List<dynamic> board) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];

    for (var line in lines) {
      if (board[line[0]] != '' &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        return board[line[0]]; // Returns 'X' or 'O'
      }
    }
    return '';
  }

  Future<void> _handleTap(int index, Map<String, dynamic> gameData) async {
    // Check 1
    if (gameData['status'] != 'playing') return;
    
    // Check 2
    if (gameData['currentTurn'] != widget.currentUserId) return;
    
    List<dynamic> board = List.from(gameData['board']);
    
    // Check 3
    if (board[index] != '') return;

    final isPlayer1 = gameData['player1'] == widget.currentUserId;
    final mySymbol = isPlayer1 ? 'X' : 'O';
    final partnerUid = isPlayer1 ? gameData['player2'] : gameData['player1'];
    
    board[index] = mySymbol;

    String winner = _checkWin(board);
    bool isDraw = false;
    if (winner == '') {
      if (!board.contains('')) {
        isDraw = true;
      }
    }

    final docRef = FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('games').doc('tictactoe');

    if (winner != '' || isDraw) {
      await docRef.update({
        'board': board,
        'status': 'finished',
        'winner': isDraw ? 'draw' : (isPlayer1 ? gameData['player1'] : gameData['player2']),
      });
    } else {
      await docRef.update({
        'board': board,
        'currentTurn': partnerUid,
      });
    }
  }

  Widget _buildTile(int index, Map<String, dynamic> gameData) {
    String symbol = gameData['board'][index] ?? '';
    Widget? iconWidget;

    if (symbol == 'X') {
      iconWidget = const Icon(Icons.favorite, color: Color(0xFFFF8B94), size: 48);
    } else if (symbol == 'O') {
      iconWidget = const Icon(Icons.star_rounded, color: Color(0xFFFFD3B6), size: 56);
    }

    return GestureDetector(
      onTap: () => _handleTap(index, gameData),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: iconWidget ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay(Map<String, dynamic> gameData) {
    String result = gameData['winner'] ?? '';
    
    bool iWon = result == widget.currentUserId;
    bool isDraw = result == 'draw';

    return Container(
      color: Colors.black45,
      child: SafeArea(
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
                  Text(
                    isDraw ? "🤝" : (iWon ? "🎉" : "💔"),
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isDraw ? "It's a Draw!" : (iWon ? "You Win!" : "Partner Wins!"),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF8B94),
                    ),
                  ),
                  const SizedBox(height: 32),
                  BouncingButton(
                    onTap: () {
                      _restartGame();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF556270)]),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "Play Again",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  BouncingButton(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8B94), Color(0xFFFFD3B6)]),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "Back to Game Zone",
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
      ),
    );
  }

  Widget _buildLobby() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("📡", style: TextStyle(fontSize: 80)),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _pulseAnimation,
          child: Text(
            "Waiting for partner to join...",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBoard(Map<String, dynamic> gameData) {
    bool isMyTurn = gameData['currentTurn'] == widget.currentUserId;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isMyTurn ? "Your Turn!" : "Waiting on Partner...",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isMyTurn ? Colors.white : Colors.white70,
            shadows: [Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AspectRatio(
            aspectRatio: 1,
            child: AnimationLimiter(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    columnCount: 3,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: _buildTile(index, gameData),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValid()) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error: Missing Couple ID or User ID',
            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Tic-Tac-Toe Live",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: DynamicBackground(
        colors: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
        child: SafeArea(
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('games').doc('tictactoe').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    final gameData = snapshot.data!.data() as Map<String, dynamic>;
                    
                    return Stack(
                      children: [
                        if (gameData['status'] == 'waiting')
                          _buildLobby()
                        else if (gameData['status'] == 'playing' || gameData['status'] == 'finished')
                          _buildLiveBoard(gameData),

                        if (gameData['status'] == 'finished')
                          _buildVictoryOverlay(gameData),
                      ],
                    );
                  },
                ),
              ),
              // Temporary Debug Overlay
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Text(
                  "Room: ${widget.coupleId} | Me: ${widget.currentUserId}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
