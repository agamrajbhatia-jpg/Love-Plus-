const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/games/how_well_do_you_know_me_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldHandleNext = `  void _handleNext() async {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final gameKey = 'howWellDoYouKnowMe';
      int vaultIndex = prefs.getInt('vault_index_$gameKey') ?? 0;
      await prefs.setInt('vault_index_$gameKey', vaultIndex + 10);
      
      int sessionsToday = prefs.getInt('sessions_played_today_$gameKey') ?? 0;
      await prefs.setInt('sessions_played_today_$gameKey', sessionsToday + 1);
      await prefs.setInt('last_session_timestamp_$gameKey', DateTime.now().millisecondsSinceEpoch);

      if (mounted) {
        context.read<AppState>().addGamePoints(15, isUser: true);
      }
      
      _showResultsOverlay();
    }
  }

  void _showResultsOverlay() async {
          final currentAppState = context.read<AppState>();
      if (currentAppState.currentCoupleId != null && currentAppState.currentUid != null) {
        await FirebaseGateService.recordGameSession('How Well Do You Know Me', currentAppState.currentCoupleId!, currentAppState.currentUid!);
      }
      showDialog(`;

const newHandleNext = `  void _handleNext() async {
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
      showDialog(`;

code = code.replace(oldHandleNext, newHandleNext);
fs.writeFileSync(path, code, 'utf8');
console.log('Fixed HowWellDoYouKnowMe');
