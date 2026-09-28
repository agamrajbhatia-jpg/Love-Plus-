import re

with open('lib/screens/games/live_card_game_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Add import for GameVault
if 'game_vault.dart' not in code:
    code = code.replace(
        "import 'package:cloud_firestore/cloud_firestore.dart';",
        "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../data/game_vault.dart';"
    )

# Remove OpenRouterService import
code = re.sub(r"import\s+'[^']*open_router_service\.dart';\n?", "", code)

# Add _isDailyLimitReached to State
if 'bool _isDailyLimitReached = false;' not in code:
    code = code.replace(
        "bool _hasApiError = false;",
        "bool _hasApiError = false;\n  bool _isDailyLimitReached = false;"
    )

# Replace _loadQuestions
load_questions_new = """
  Future<void> _loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check Daily Limit
    final now = DateTime.now();
    final dateString = '${now.year}-${now.month}-${now.day}';
    final lastPlayedDate = prefs.getString('last_played_date_${_deckKey}');
    int sessionsPlayedToday = prefs.getInt('sessions_played_today_${_deckKey}') ?? 0;
    
    if (lastPlayedDate != dateString) {
      sessionsPlayedToday = 0;
      await prefs.setString('last_played_date_${_deckKey}', dateString);
      await prefs.setInt('sessions_played_today_${_deckKey}', 0);
    }
    
    // if (user.isPremium) return true; // premium bypass placeholder
    if (sessionsPlayedToday >= 2) {
      if (mounted) {
        setState(() {
          _isDailyLimitReached = true;
          _isLoading = false;
        });
      }
      return;
    }
    
    // Check if cooldown is active
    final cooldownTimeMs = prefs.getInt('${_deckKey}_unlock_time');
    if (cooldownTimeMs != null) {
      final unlockTime = DateTime.fromMillisecondsSinceEpoch(cooldownTimeMs);
      if (DateTime.now().isBefore(unlockTime)) {
        _startCooldownTimer(unlockTime);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      } else {
        _isCooldownActive = true;
        _cooldownRemaining = Duration.zero;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
    }

    // Read progress index
    int vaultIndex = prefs.getInt('vault_index_${_deckKey}') ?? 0;
    final vaultDeck = GameVault.decks[widget.deckName] ?? GameVault.decks['Icebreakers & Fun']!;
    
    if (vaultIndex >= vaultDeck.length) {
      vaultIndex = 0; 
      await prefs.setInt('vault_index_${_deckKey}', 0);
    }
    
    // Slice exactly 10 cards
    final endIndex = (vaultIndex + 10 <= vaultDeck.length) ? vaultIndex + 10 : vaultDeck.length;
    _questions = vaultDeck.sublist(vaultIndex, endIndex);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
"""
code = re.sub(r'Future<void> _loadQuestions\(\) async \{.*?(?=void _startCooldownTimer)', load_questions_new.strip() + '\n\n  ', code, flags=re.DOTALL)

# Replace _handleDeckCompletion
handle_deck_new = """
  Future<void> _handleDeckCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Increment vault index
    int vaultIndex = prefs.getInt('vault_index_${_deckKey}') ?? 0;
    await prefs.setInt('vault_index_${_deckKey}', vaultIndex + 10);
    
    // Increment daily sessions
    final now = DateTime.now();
    final dateString = '${now.year}-${now.month}-${now.day}';
    int sessionsPlayedToday = prefs.getInt('sessions_played_today_${_deckKey}') ?? 0;
    await prefs.setString('last_played_date_${_deckKey}', dateString);
    await prefs.setInt('sessions_played_today_${_deckKey}', sessionsPlayedToday + 1);

    // Wipe memory
    _questions.clear();

    // Set 5m cooldown
    final unlockTime = DateTime.now().add(const Duration(minutes: 5));
    await prefs.setInt('${_deckKey}_unlock_time', unlockTime.millisecondsSinceEpoch);
    
    NotificationService.scheduleNotification(
      id: widget.deckName.hashCode,
      title: '✨ Your Next 10 Cards Are Ready!',
      body: 'Tap to continue playing with your partner.',
      delay: const Duration(minutes: 5),
    );

    _startCooldownTimer(unlockTime);
  }
"""
code = re.sub(r'Future<void> _handleDeckCompletion\(\) async \{.*?(?=Future<void> _fetchNewDeckAndSwap)', handle_deck_new.strip() + '\n\n  ', code, flags=re.DOTALL)

# Replace _fetchNewDeckAndSwap with _fetchNextVaultDeck
fetch_next_new = """
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
        FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('live_game_session').doc('couple_cards').update({
          'current_card_index': 0,
        });
      }
      setState(() {
        _isSyncing = false;
        _isCooldownActive = false;
      });
    }
  }
"""
code = re.sub(r'Future<void> _fetchNewDeckAndSwap\(\) async \{.*?(?=Widget _buildCompletionCard)', fetch_next_new.strip() + '\n\n  ', code, flags=re.DOTALL)

# Replace calls to _fetchNewDeckAndSwap
code = code.replace('_fetchNewDeckAndSwap', '_fetchNextVaultDeck')

# Inject daily limit UI
lock_screen_ui = """
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
                                          'Come back tomorrow for new cards! ⏳\\n\\n// if (user.isPremium) return true;',
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
"""

code = code.replace(
    "Expanded(\n                        child: Padding(\n                          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0, top: 8.0),\n                          child: _isCooldownActive",
    lock_screen_ui + "                          child: Padding(\n                            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0, top: 8.0),\n                            child: _isCooldownActive"
)

with open('lib/screens/games/live_card_game_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Done")
