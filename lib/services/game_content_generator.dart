import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'open_router_service.dart';
import '../data/master_games_content.dart';

class GameContentGenerator {
  final OpenRouterService _aiService = OpenRouterService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchDailyQuestionsAndSave(String coupleId, String gameType) async {
    String formatInstructions = "";

    switch (gameType) {
      case 'wouldYouRather':
        formatInstructions = 'Each question object must have two objects: "boy_asks" and "girl_asks". Inside each, provide "question", "optionA", and "optionB".';
        break;
      case 'howWellDoYouKnowMe':
        formatInstructions = 'Each question object must have two objects: "boy_asks" and "girl_asks". Inside each, provide "question" and "options" (a list of 4 string options).';
        break;
      case 'scenario':
      case 'howMad':
        formatInstructions = 'Each question object must have two objects: "boy_asks" and "girl_asks". Inside each, provide "scenario" (a string).';
        break;
      case 'exposeUs':
        formatInstructions = 'Each question object must just be a string. But wait, the schema requires boy_asks and girl_asks. Make each question object have "boy_asks": {"scenario": "string"} and "girl_asks": {"scenario": "string"} where the scenario is a question like "Who is more likely to...".';
        break;
      default:
        formatInstructions = 'Each question object must have two strings: "boy_asks" and "girl_asks".';
    }

    final prompt = '''You are a relationship game designer. Give 5 questions for game: $gameType. Return JSON object with list "questions". $formatInstructions''';

    final responseJsonStr = await _aiService.generateText(
      prompt: prompt,
      model: 'openai/gpt-4o-mini',
      responseFormat: {"type": "json_object"},
    );

    try {
      if (responseJsonStr.startsWith('Error:')) {
        print('API Error: $responseJsonStr');
        _loadFallbackQuestions(coupleId, gameType);
        return;
      }
      final parsed = jsonDecode(responseJsonStr);
      final questions = parsed['questions'] as List;

      await _firestore.collection('couples').doc(coupleId).update({
        '${gameType}_questions': questions,
      });
    } catch (e) {
      print('Error parsing or saving AI questions: $e\nResponse was: $responseJsonStr');
      _loadFallbackQuestions(coupleId, gameType);
    }
  }

  Future<void> _loadFallbackQuestions(String coupleId, String gameType) async {
    List<dynamic> fallbackData = [];
    switch (gameType) {
      case 'wouldYouRather':
        fallbackData = masterWouldYouRather.take(5).toList();
        break;
      case 'howWellDoYouKnowMe':
        fallbackData = masterHowWell.take(5).toList();
        break;
      case 'scenario':
        fallbackData = masterScenarioScale.take(5).toList();
        break;
      case 'howMad':
        fallbackData = masterHowMad.take(5).toList();
        break;
      case 'exposeUs':
        fallbackData = [
          {"boy_asks": {"scenario": "Who takes way longer to admit they were actually wrong?"}, "girl_asks": {"scenario": "Who takes way longer to admit they were actually wrong?"}},
          {"boy_asks": {"scenario": "Who is more likely to secretly check the other person’s search history?"}, "girl_asks": {"scenario": "Who is more likely to secretly check the other person’s search history?"}},
          {"boy_asks": {"scenario": "Who is more likely to fall asleep 10 minutes into a movie they picked?"}, "girl_asks": {"scenario": "Who is more likely to fall asleep 10 minutes into a movie they picked?"}},
          {"boy_asks": {"scenario": "Who spends more money on random things they don’t actually need?"}, "girl_asks": {"scenario": "Who spends more money on random things they don’t actually need?"}},
          {"boy_asks": {"scenario": "Who is the worse driver, hands down?"}, "girl_asks": {"scenario": "Who is the worse driver, hands down?"}},
        ];
        break;
    }

    try {
      await _firestore.collection('couples').doc(coupleId).update({
        '${gameType}_questions': fallbackData,
      });
      print('Saved fallback questions for $gameType');
    } catch (e) {
      print('Error saving fallback questions: $e');
    }
  }
}
