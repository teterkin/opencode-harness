import fnmatch
import json
import sys

agent_id, action, resource = sys.argv[1], sys.argv[2], sys.argv[3]

agents = json.load(sys.stdin)["data"]
agent = next((item for item in agents if item["id"] == agent_id), None)
if agent is None:
    print("absent")
    raise SystemExit(0)

# Rules are ordered, the last matching rule wins: an agent can narrow what the
# global config allowed, but not widen it.
effect = "absent"
for rule in agent.get("permissions", []):
    if fnmatch.fnmatch(action, rule["action"]) and fnmatch.fnmatch(
        resource, rule["resource"]
    ):
        effect = rule["effect"]

print(effect)
