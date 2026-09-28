import os
import re

base_dir = r"C:\Users\agamr\.gemini\antigravity\scratch\couple_app\lib\screens"

# 1. Patch Game Zone (remove locks)
game_zone = os.path.join(base_dir, "modes", "game_zone_screen.dart")
with open(game_zone, "r", encoding="utf-8") as f:
    content = f.read()

# simple regex to remove the premium locks
content = re.sub(r'final lastPlayed = appState\.lastPlayed.*?;.*?if \(lastPlayed != null &&.*?_showPremiumLock\(context\);\s*\} else \{\s*(Navigator\.push\([^;]+\);)\s*\}', r'\1', content, flags=re.DOTALL)
content = re.sub(r'final lastPlayed = appState\.lastPlayed.*?;.*?if \(lastPlayed != null &&.*?_showPremiumLock\(context\);\s*\} else \{\s*(Navigator\.push\([^;]+;\s*\)\s*;)\s*\}', r'\1', content, flags=re.DOTALL)

# specifically handle multi-line navigator push
content = re.sub(r'final lastPlayed.*?_showPremiumLock\(context\);\s*\} else \{\s*(Navigator\.push\([\s\S]*?\);)\s*\}', r'\1', content, flags=re.DOTALL)


with open(game_zone, "w", encoding="utf-8") as f:
    f.write(content)

# 2. Patch WouldYouRatherScreen
wyr_path = os.path.join(base_dir, "games", "would_you_rather_screen.dart")
with open(wyr_path, "r", encoding="utf-8") as f:
    wyr_code = f.read()

wyr_code = wyr_code.replace(
    "import '../../data/master_games_content.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
)

wyr_code = wyr_code.replace(
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
)

wyr_code = wyr_code.replace(
    "actions: [", "actions: []"
) # just in case, though there are no actions. Let's add the button explicitly.
if "actions:" not in wyr_code:
    wyr_code = wyr_code.replace(
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
    )

with open(wyr_path, "w", encoding="utf-8") as f:
    f.write(wyr_code)

print("Would you rather patched")

# 3. Patch Scenario Scale Screen
ss_path = os.path.join(base_dir, "games", "scenario_scale_screen.dart")
with open(ss_path, "r", encoding="utf-8") as f:
    ss_code = f.read()

ss_code = ss_code.replace(
    "import '../../data/master_games_content.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
)

ss_code = ss_code.replace(
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
)

if "actions:" not in ss_code:
    ss_code = ss_code.replace(
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
    )

with open(ss_path, "w", encoding="utf-8") as f:
    f.write(ss_code)

print("Scenario patched")

# 4. Patch How Mad Screen
hm_path = os.path.join(base_dir, "games", "how_mad_screen.dart")
with open(hm_path, "r", encoding="utf-8") as f:
    hm_code = f.read()

hm_code = hm_code.replace(
    "import '../../data/master_games_content.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport '../../services/game_content_generator.dart';"
)

hm_code = hm_code.replace(
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
)

if "actions:" not in hm_code:
    hm_code = hm_code.replace(
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
    )

with open(hm_path, "w", encoding="utf-8") as f:
    f.write(hm_code)

print("How Mad patched")

