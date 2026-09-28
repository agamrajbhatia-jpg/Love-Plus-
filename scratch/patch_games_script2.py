import os
import re

base_dir = r"C:\Users\agamr\.gemini\antigravity\scratch\couple_app\lib\screens"

# 5. Patch How Well Do You Know Me Screen
hw_path = os.path.join(base_dir, "games", "how_well_do_you_know_me_screen.dart")
with open(hw_path, "r", encoding="utf-8") as f:
    hw_code = f.read()

hw_code = hw_code.replace(
    "import '../../data/master_games_content.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
)

hw_code = hw_code.replace(
    '''  Future<void> _initGame() async {
    final appState = context.read<AppState>();
    final role = appState.userRole;
    final startIndex = await appState.fetchDailyGameIndex('howWell', 5);
    
    var slice = masterHowWell.skip(startIndex).take(5).toList();
    if (slice.isEmpty || slice.length < 5) {
      final wrappedIndex = startIndex % masterHowWell.length;
      slice = masterHowWell.skip(wrappedIndex).take(5).toList();
    }

    if (mounted) {
      setState(() {
        _activeQuestions = slice.map((q) {
          final data = role == "BF" ? q['boy_asks'] : q['girl_asks'];
          return {
            "question": data['question'],
            "options": data['options']
          };
        }).toList();
        _isLoading = false;
      });
    }
  }''',
    '''  Future<void> _initGame() async {
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    if (coupleId == null) return;
    
    FirebaseFirestore.instance.collection('couples').doc(coupleId).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final questions = data['howWellDoYouKnowMe_questions'] as List<dynamic>?;
      if (questions == null || questions.isEmpty) {
        GameContentGenerator().fetchDailyQuestionsAndSave(coupleId, 'howWellDoYouKnowMe');
      } else {
        if (mounted) {
          setState(() {
            _activeQuestions = questions.map((q) {
              final qData = appState.userRole == "BF" ? q['boy_asks'] : q['girl_asks'];
              return {
                "question": qData['question'],
                "options": qData['options']
              };
            }).toList();
            _isLoading = false;
          });
        }
      }
    });
  }'''
)

if "actions:" not in hw_code:
    hw_code = hw_code.replace(
        "centerTitle: true,",
        '''centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Debug: Generate New Questions',
            onPressed: () {
              if (_mode == GameMode.answerQuestions) {
                setState(() => _isLoading = true);
                final appState = context.read<AppState>();
                GameContentGenerator().fetchDailyQuestionsAndSave(appState.currentCoupleId!, 'howWellDoYouKnowMe');
              }
            },
          ),
        ],'''
    )

with open(hw_path, "w", encoding="utf-8") as f:
    f.write(hw_code)

print("How well patched")

# 6. Patch Expose Us Screen
eu_path = os.path.join(base_dir, "games", "expose_us_screen.dart")
with open(eu_path, "r", encoding="utf-8") as f:
    eu_code = f.read()

eu_code = eu_code.replace(
    "import '../../widgets/dynamic_background.dart';",
    "import '../../widgets/dynamic_background.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
)

eu_code = eu_code.replace(
    '''  final List<String> _questions = [
    "Who takes way longer to admit they were actually wrong?",
    "Who is more likely to secretly check the other person’s search history?",
    "Who is more likely to fall asleep 10 minutes into a movie they picked?",
    "Who spends more money on random things they don’t actually need?",
    "Who is more likely to start a playful argument just because they are bored?",
    "Who is the worse driver, hands down?",
    "Who gets jealous more easily over little things?",
    "Who takes significantly longer to get ready to go out?",
    "Who is more likely to survive a zombie apocalypse?",
    "Who is more likely to eat the leftovers the other person was saving?",
    "Who gives the best silent treatment?",
    "Who is actually the funnier one in the relationship?",
  ];''',
    '''  List<String> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final coupleId = appState.currentCoupleId;
      if (coupleId == null) return;
      
      FirebaseFirestore.instance.collection('couples').doc(coupleId).snapshots().listen((doc) {
        if (!doc.exists) return;
        final data = doc.data() as Map<String, dynamic>;
        final questions = data['exposeUs_questions'] as List<dynamic>?;
        if (questions == null || questions.isEmpty) {
          GameContentGenerator().fetchDailyQuestionsAndSave(coupleId, 'exposeUs');
        } else {
          if (mounted) {
            setState(() {
              _questions = questions.map((q) {
                final qData = appState.userRole == "BF" ? q['boy_asks'] : q['girl_asks'];
                return qData['scenario'] as String;
              }).toList();
              _isLoading = false;
            });
          }
        }
      });
    });
  }'''
)

if "actions:" not in eu_code:
    eu_code = eu_code.replace(
        "centerTitle: true,",
        '''centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Debug: Generate New Questions',
            onPressed: () {
              setState(() => _isLoading = true);
              final appState = context.read<AppState>();
              GameContentGenerator().fetchDailyQuestionsAndSave(appState.currentCoupleId!, 'exposeUs');
            },
          ),
        ],'''
    )

eu_code = eu_code.replace(
    '''  @override
  Widget build(BuildContext context) {
    return Scaffold(''',
    '''  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD81B60))),
      );
    }
    return Scaffold('''
)

with open(eu_path, "w", encoding="utf-8") as f:
    f.write(eu_code)

print("Expose Us patched")

