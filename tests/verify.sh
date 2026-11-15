#!/usr/bin/env bash
# Проверка, что установленный харнесс подхватывается opencode 2.x.
# Читает эффективное состояние через HTTP API opencode, а не через файлы:
# файл на диске не доказывает, что правило применилось.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0

ok() { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; FAILED=$((FAILED + 1)); }

check() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == *"$expected"* ]]; then
        ok "$label"
    else
        bad "$label (ожидал: $expected, получил: ${actual:0:160})"
    fi
}

check_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        ok "$label"
    else
        bad "$label (ожидал: [$expected], получил: [$actual])"
    fi
}

echo "== opencode =="
VERSION="$(opencode --version 2>&1)"
check "opencode запускается" "opencode v" "$VERSION"
printf '       версия: %s\n' "$VERSION"

CONFIG="$(opencode api GET /api/config 2>/dev/null)"
check_eq "конфиг читается и валиден" "" \
    "$(printf '%s' "$CONFIG" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>&1)"
printf '%s' "$CONFIG" | python3 -c '
import json, sys
for doc in json.load(sys.stdin):
    info = doc.get("info") or {}
    if "model" in info or "default_agent" in info:
        print("       модель: %s | default_agent: %s" % (
            info.get("model", "—"), info.get("default_agent", "—")))
'

AGENTS="$(opencode api GET /api/agent 2>/dev/null)"
COMMANDS="$(opencode api GET /api/command 2>/dev/null)"
SKILLS="$(opencode api GET /api/skill 2>/dev/null)"

has_item() {
    printf '%s' "$1" | python3 -c "
import json, sys
ids = [item['id'] if 'id' in item else item['name'] for item in json.load(sys.stdin)['data']]
sys.exit(0 if '$2' in ids else 1)
"
}

agent_mode() {
    printf '%s' "$AGENTS" | python3 -c "
import json, sys
print(next(item['mode'] for item in json.load(sys.stdin)['data'] if item['id'] == '$1'))
"
}

permission_rule() {
    printf '%s' "$AGENTS" | python3 "$SCRIPT_DIR/find_permission.py" "$1" "$2" "$3"
}

echo
echo "== agents =="
for agent in implementer plan reviewer; do
    if has_item "$AGENTS" "$agent"; then
        ok "агент $agent определён"
    else
        bad "агент $agent не найден"
    fi
done
check_eq "implementer: primary" "primary" "$(agent_mode implementer)"
check_eq "reviewer: subagent" "subagent" "$(agent_mode reviewer)"

echo
echo "== permissions =="
check "plan: edit запрещён" "deny" "$(permission_rule plan edit 'src/main.py')"
check "reviewer: edit запрещён" "deny" "$(permission_rule reviewer edit 'src/main.py')"
check "implementer: edit разрешён" "allow" "$(permission_rule implementer edit 'src/main.py')"
for gitcmd in 'git reset --hard' 'git checkout main' 'git rebase main' 'git merge main'; do
    if [[ "$(permission_rule implementer shell "$gitcmd")" == "deny" ]]; then
        ok "implementer: $gitcmd запрещён"
    else
        bad "implementer: $gitcmd НЕ запрещён (было: $(permission_rule implementer shell "$gitcmd"))"
    fi
done
for gitcmd in 'git commit -m x' 'git push'; do
    if [[ "$(permission_rule implementer shell "$gitcmd")" == "deny" ]]; then
        bad "implementer: $gitcmd запрещён, а должен быть разрешён"
    else
        ok "implementer: $gitcmd не запрещён"
    fi
done
check "reviewer: git diff разрешён" "allow" "$(permission_rule reviewer shell 'git diff')"

echo
echo "== commands =="
for cmd in prd tdd review; do
    if has_item "$COMMANDS" "$cmd"; then
        ok "команда /$cmd зарегистрирована"
    else
        bad "команда /$cmd не найдена"
    fi
done

echo
echo "== skills =="
for skill in tdd-workflow prd-authoring; do
    if has_item "$SKILLS" "$skill"; then
        ok "скилл $skill подхвачен"
    else
        bad "скилл $skill не найден"
    fi
done

echo
printf 'итого провалено: %d\n' "$FAILED"
[[ "$FAILED" -eq 0 ]]
