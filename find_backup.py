import json
import os

path = r"C:\Users\agamr\.gemini\antigravity\brain\141212a9-a227-405b-b8ad-d74fde9fb413\.system_generated\logs\transcript_full.jsonl"

with open(path, 'r', encoding='utf-8') as f:
    for line in f:
        if 'class GameZoneScreen extends StatefulWidget' in line:
            print("Found GameZoneScreen content in transcript!")
            try:
                data = json.loads(line)
                # print snippet
                if 'content' in data:
                    print(data['content'][:1000])
                if 'tool_calls' in data:
                    for call in data['tool_calls']:
                        if 'CodeContent' in call.get('arguments', {}):
                            print("Found CodeContent!")
            except Exception as e:
                pass
