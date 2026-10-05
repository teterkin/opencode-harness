import json
import sys

agent = json.load(sys.stdin)
tool, pattern = sys.argv[1], sys.argv[2]

# Правила применяются по порядку, последнее совпадение побеждает:
# агент может сузить то, что глобальный конфиг разрешил, но не наоборот.
action = "absent"
for rule in agent.get("permission", []):
    if rule.get("permission") == tool and rule.get("pattern") == pattern:
        action = rule.get("action")

print(action)