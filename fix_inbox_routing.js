const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

const oldRouting = `                onTap: () {
                  final safeRoute = template.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
                  if (safeRoute == 'couplecards') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCardGameScreen(deckName: 'Custom Deck', customQuestions: questions, customDeckId: doc.id)));
                  } else if (safeRoute == 'wouldyourather') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WouldYouRatherScreen(customQuestions: questions, customDeckId: doc.id)));
                  }
                  // ADD OTHER GAMES HERE IF NEEDED LATER
                },`;

const newRouting = `                onTap: () {
                  final cardTitle = template;
                  if (cardTitle.toLowerCase().contains('would you rather')) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WouldYouRatherScreen(customQuestions: questions, customDeckId: doc.id)));
                    return;
                  }
                  final safeRoute = template.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
                  if (safeRoute == 'couplecards') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCardGameScreen(deckName: 'Custom Deck', customQuestions: questions, customDeckId: doc.id)));
                  }
                  // ADD OTHER GAMES HERE IF NEEDED LATER
                },`;

gzs = gzs.replace(oldRouting, newRouting);
fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed inbox routing');
