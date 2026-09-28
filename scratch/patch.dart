import 'dart:io';

void main() {
  final baseDir = r"C:\Users\agamr\.gemini\antigravity\scratch\couple_app\lib\screens";

  // 1. Patch Game Zone
  final gzFile = File("$baseDir/modes/game_zone_screen.dart");
  var gzCode = gzFile.readAsStringSync();
  gzCode = gzCode.replaceAll(RegExp(r'final lastPlayed = appState\.lastPlayed.*?;.*?if \(lastPlayed != null &&.*?_showPremiumLock\(context\);\s*\} else \{\s*(Navigator\.push\([^;]+\);)\s*\}', dotAll: true), r'\1');
  gzCode = gzCode.replaceAll(RegExp(r'final lastPlayed = appState\.lastPlayed.*?;.*?if \(lastPlayed != null &&.*?_showPremiumLock\(context\);\s*\} else \{\s*(Navigator\.push\([^;]+;\s*\)\s*;)\s*\}', dotAll: true), r'\1');
  gzCode = gzCode.replaceAll(RegExp(r'final lastPlayed.*?_showPremiumLock\(context\);\s*\} else \{\s*(Navigator\.push\([\s\S]*?\);)\s*\}', dotAll: true), r'\1');
  gzFile.writeAsStringSync(gzCode);
  print("Game Zone patched");

  // 2. Patch WouldYouRatherScreen
  final wyrFile = File("$baseDir/games/would_you_rather_screen.dart");
  var wyrCode = wyrFile.readAsStringSync();
  wyrCode = wyrCode.replaceAll(
    "import '../../data/master_games_content.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
  );
  wyrCode = wyrCode.replaceAll(
    '''  Future<void> _initGame() async {
    final appState = context.read<AppState>();
    final role = appState.userRole;
    
    final startIndex = await appState.fetchDailyGameIndex('wouldYouRather', 5);
    
    var slice = masterWouldYouRather.skip(startIndex).take(5).toList();
    if (slice.isEmpty || slice.length < 5) {
      final wrappedIndex = startIndex % masterWouldYouRather.length;
      slice = masterWouldYouRather.skip(wrappedIndex).take(5).toList();
    }

    if (mounted) {
      setState(() {
        _questions = slice.map((q) {
          final data = role == "BF" ? q['boy_asks'] : q['girl_asks'];
          return {
            "question": data['question'] as String,
            "optionA": data['optionA'] as String,
            "optionB": data['optionB'] as String,
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
      final questions = data['wouldYouRather_questions'] as List<dynamic>?;
      if (questions == null || questions.isEmpty) {
        GameContentGenerator().fetchDailyQuestionsAndSave(coupleId, 'wouldYouRather');
      } else {
        if (mounted) {
          setState(() {
            _questions = questions.map((q) {
              final qData = appState.userRole == "BF" ? q['boy_asks'] : q['girl_asks'];
              return {
                "question": qData['question'] as String,
                "optionA": qData['optionA'] as String,
                "optionB": qData['optionB'] as String,
              };
            }).toList();
            _isLoading = false;
          });
        }
      }
    });
  }'''
  );
  if (!wyrCode.contains("actions:")) {
    wyrCode = wyrCode.replaceAll(
      "centerTitle: true,",
      '''centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Debug: Generate New Questions',
            onPressed: () {
              setState(() => _isLoading = true);
              final appState = context.read<AppState>();
              GameContentGenerator().fetchDailyQuestionsAndSave(appState.currentCoupleId!, 'wouldYouRather');
            },
          ),
        ],'''
    );
  }
  wyrFile.writeAsStringSync(wyrCode);
  print("Would You Rather patched");

  // 3. Scenario Scale Screen
  final ssFile = File("$baseDir/games/scenario_scale_screen.dart");
  var ssCode = ssFile.readAsStringSync();
  ssCode = ssCode.replaceAll(
    "import '../../data/master_games_content.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
  );
  ssCode = ssCode.replaceAll(
    '''  Future<void> _initGame() async {
    final appState = context.read<AppState>();
    final role = appState.userRole;
    final startIndex = await appState.fetchDailyGameIndex('scenario', 5);
    
    var slice = masterScenarioScale.skip(startIndex).take(5).toList();
    if (slice.isEmpty || slice.length < 5) {
      final wrappedIndex = startIndex % masterScenarioScale.length;
      slice = masterScenarioScale.skip(wrappedIndex).take(5).toList();
    }

    if (mounted) {
      setState(() {
        _activeScenarios = slice.map((s) {
          final scenarioData = role == "BF" ? s['boy_asks'] : s['girl_asks'];
          return {"scenario": scenarioData['scenario'] as String};
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
      final scenarios = data['scenario_questions'] as List<dynamic>?;
      if (scenarios == null || scenarios.isEmpty) {
        GameContentGenerator().fetchDailyQuestionsAndSave(coupleId, 'scenario');
      } else {
        if (mounted) {
          setState(() {
            _activeScenarios = scenarios.map((s) {
              final scenarioData = appState.userRole == "BF" ? s['boy_asks'] : s['girl_asks'];
              return {"scenario": scenarioData['scenario'] as String};
            }).toList();
            _isLoading = false;
          });
        }
      }
    });
  }'''
  );
  if (!ssCode.contains("actions:")) {
    ssCode = ssCode.replaceAll(
      "centerTitle: true,",
      '''centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Debug: Generate New Questions',
            onPressed: () {
              if (_mode == ScaleMode.setup) {
                setState(() => _isLoading = true);
                final appState = context.read<AppState>();
                GameContentGenerator().fetchDailyQuestionsAndSave(appState.currentCoupleId!, 'scenario');
              }
            },
          ),
        ],'''
    );
  }
  ssFile.writeAsStringSync(ssCode);
  print("Scenario patched");

  // 4. How Mad Screen
  final hmFile = File("$baseDir/games/how_mad_screen.dart");
  var hmCode = hmFile.readAsStringSync();
  hmCode = hmCode.replaceAll(
    "import '../../data/master_games_content.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
  );
  hmCode = hmCode.replaceAll(
    '''  Future<void> _initGame() async {
    final appState = context.read<AppState>();
    final role = appState.userRole;
    final startIndex = await appState.fetchDailyGameIndex('howMad', 5);
    
    var slice = masterHowMad.skip(startIndex).take(5).toList();
    if (slice.isEmpty || slice.length < 5) {
      final wrappedIndex = startIndex % masterHowMad.length;
      slice = masterHowMad.skip(wrappedIndex).take(5).toList();
    }

    if (mounted) {
      setState(() {
        _activeScenarios = slice.map((s) {
          final scenarioData = role == "BF" ? s['boy_asks'] : s['girl_asks'];
          return {"scenario": scenarioData['scenario'] as String};
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
      final scenarios = data['howMad_questions'] as List<dynamic>?;
      if (scenarios == null || scenarios.isEmpty) {
        GameContentGenerator().fetchDailyQuestionsAndSave(coupleId, 'howMad');
      } else {
        if (mounted) {
          setState(() {
            _activeScenarios = scenarios.map((s) {
              final scenarioData = appState.userRole == "BF" ? s['boy_asks'] : s['girl_asks'];
              return {"scenario": scenarioData['scenario'] as String};
            }).toList();
            _isLoading = false;
          });
        }
      }
    });
  }'''
  );
  if (!hmCode.contains("actions:")) {
    hmCode = hmCode.replaceAll(
      "centerTitle: true,",
      '''centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Debug: Generate New Questions',
            onPressed: () {
              if (_mode == HowMadMode.setup) {
                setState(() => _isLoading = true);
                final appState = context.read<AppState>();
                GameContentGenerator().fetchDailyQuestionsAndSave(appState.currentCoupleId!, 'howMad');
              }
            },
          ),
        ],'''
    );
  }
  hmFile.writeAsStringSync(hmCode);
  print("How Mad patched");

  // 5. How Well
  final hwFile = File("$baseDir/games/how_well_do_you_know_me_screen.dart");
  var hwCode = hwFile.readAsStringSync();
  hwCode = hwCode.replaceAll(
    "import '../../data/master_games_content.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
  );
  hwCode = hwCode.replaceAll(
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
  );
  if (!hwCode.contains("actions:")) {
    hwCode = hwCode.replaceAll(
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
    );
  }
  hwFile.writeAsStringSync(hwCode);
  print("How well patched");

  // 6. Expose Us
  final euFile = File("$baseDir/games/expose_us_screen.dart");
  var euCode = euFile.readAsStringSync();
  euCode = euCode.replaceAll(
    "import '../../widgets/dynamic_background.dart';",
    "import '../../widgets/dynamic_background.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
  );
  euCode = euCode.replaceAll(
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
  );
  if (!euCode.contains("actions:")) {
    euCode = euCode.replaceAll(
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
    );
  }
  euCode = euCode.replaceAll(
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
  );
  euFile.writeAsStringSync(euCode);
  print("Expose Us patched");
}
