const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let content = fs.readFileSync(path, 'utf8');

const map = {
  'Ã¢Å¡â€ Ã¯Â¸Â ': '⚔️',
  'Ã°Å¸Å½Ë†': '🎈',
  'Ã°Å¸â€™Â¬': '💬',
  'Ã°Å¸Å½Â¯': '🎯',
  'Ã°Å¸â€™Â¡': '💡',
  'Ã°Å¸Å’Â¶Ã¯Â¸Â ': '🌶️',
  'Ã°Å¸Â¤â€ ': '🤔',
  'Ã¢Å¡â€“Ã¯Â¸Â ': '⚖️',
  'Ã¢Â Å’': '❌',
  'Ã°Å¸ËœÂ¤': '😤',
  'Ã°Å¸Â«Â£': '🫣',
  'Ã°Å¸Â â€ ': '🏆',
  'Ã°Å¸Å½Â¨': '🎨',
  'Ã°Å¸â€™Å’': '💌',
  'Ã¢Â Â³': '⏳',
  'Ã°Å¸â€ â€™': '🔒',
  'Ã¢ÂœÂ¨': '✨',
  'Ã°Å¸â€™Â¥': '💥',
  'Ã°Å¸Å½Â²': '🎲',
  'Ã¢Â Â¤Ã¯Â¸Â ': '❤️'
};

for (const [bad, good] of Object.entries(map)) {
  content = content.split(bad).join(good);
}
fs.writeFileSync(path, content, 'utf8');
console.log('Fixed encoding!');
