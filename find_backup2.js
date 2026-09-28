const fs = require('fs');
const readline = require('readline');
const path = 'C:\\Users\\agamr\\.gemini\\antigravity\\brain\\141212a9-a227-405b-b8ad-d74fde9fb413\\.system_generated\\logs\\transcript_full.jsonl';

const fileStream = fs.createReadStream(path);
const rl = readline.createInterface({
  input: fileStream,
  crlfDelay: Infinity
});

let bestContent = null;
let found = 0;

rl.on('line', (line) => {
  if (line.includes('_buildCustomGamesInbox') && line.includes('_buildDeckButton')) {
    found++;
    try {
      const data = JSON.parse(line);
      if (data.content && data.content.includes('_buildCustomGamesInbox')) {
         bestContent = data.content;
      }
      if (data.tool_calls) {
        data.tool_calls.forEach(t => {
          if (t.arguments && t.arguments.ReplacementContent) {
             // Maybe it was replaced here? But we want the full file.
          }
        });
      }
      if (data.type === 'TOOL_RESPONSE' && data.content.includes('_buildCustomGamesInbox')) {
         bestContent = data.content;
      }
    } catch (e) {}
  }
});

rl.on('close', () => {
  console.log('Found occurrences:', found);
  if (bestContent) {
    fs.writeFileSync('C:\\Users\\agamr\\Documents\\CoupleApp\\recovered2.txt', bestContent, 'utf8');
    console.log('Saved best content to recovered2.txt');
  }
});
