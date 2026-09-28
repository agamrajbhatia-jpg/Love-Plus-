const fs = require('fs');
const readline = require('readline');
const rl = readline.createInterface({
  input: fs.createReadStream('C:\\\\Users\\\\agamr\\\\.gemini\\\\antigravity\\\\brain\\\\141212a9-a227-405b-b8ad-d74fde9fb413\\\\.system_generated\\\\logs\\\\transcript_full.jsonl', {encoding: 'utf8'})
});

rl.on('line', (line) => {
  const obj = JSON.parse(line);
  if (obj.step_index === 358) {
    if (obj.tool_calls) {
      for (const call of obj.tool_calls) {
        if (call.name === 'write_to_file' && call.args.TargetFile.includes('game_zone_screen.dart')) {
          const lines = call.args.CodeContent.split('\\n');
          const matches = lines.filter(l => l.includes('Icebreakers') || l.includes('Deep Dive') || l.includes('Playful') || l.includes('Spontaneous'));
          console.log(matches.join('\\n'));
        }
      }
    }
  }
});
