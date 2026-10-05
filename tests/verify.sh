#!/usr/bin/env bash
# Проверка, что текущая настройка харнесса подхватывается opencode.
# Запускать из открытой сессии не нужно, opencode можно перезапустить позже.

set -uo pipefail

FAILED=0

ok() { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; FAILED=$((FAILED + 1)); }

check() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == *"$expected"* ]]; then
        ok "$label"
    else
        bad "$label (ожидал: $expected)"
    fi
}

check_absent() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        ok "$label"
    else
        bad "$label (не ожидалось: $needle)"
    fi
}

echo "== config =="
CONFIG="$(opencode debug config 2>&1)"
check "конфиг валиден" '"model"' "$CONFIG"
check "модель харнесса" "opencode/big-pickle" "$CONFIG"
check "агент по умолчанию" '"default_agent": "implementer"' "$CONFIG"

echo
echo "== agents =="
for agent in implementer plan reviewer; do
    if opencode debug agent "$agent" >/dev/null 2>&1; then
        ok "агент $agent определён"
    else
        bad "агент $agent не найден"
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

permission_rule() {
    # Печатает действие правила агента или "absent".
    opencode debug agent "$1" 2>/dev/null \
        | python3 "$SCRIPT_DIR/find_permission.py" "$2" "$3"
}

denies() {
    # 0 если правило есть и запрещает, 1 иначе.
    [[ "$(permission_rule "$1" "$2" "$3")" == "deny" ]]
}

check "plan: edit запрещён" "deny" "$(permission_rule plan edit '*')"
check "reviewer: edit запрещён" "deny" "$(permission_rule reviewer edit '*')"
check "implementer: edit разрешён" "allow" "$(permission_rule implementer edit '*')"
for gitcmd in 'git commit*' 'git push*' 'git reset*' 'git rebase*' 'git merge*'; do
    if denies implementer bash "$gitcmd"; then
        ok "implementer: $gitcmd запрещён"
    else
        bad "implementer: $gitcmd НЕ запрещён (было: $(permission_rule implementer bash "$gitcmd"))"
    fi
done

echo
echo "== commands =="
for cmd in prd tdd review; do
    if opencode debug config 2>/dev/null | python3 -c "
import json, sys
config = json.load(sys.stdin)
sys.exit(0 if '$cmd' in config.get('command', {}) else 1)
" 2>/dev/null; then
        ok "команда /$cmd зарегистрирована"
    else
        bad "команда /$cmd не найдена"
    fi
done

echo
echo "== skills =="
SKILLS="$(opencode debug skill 2>/dev/null)"
check "скилл tdd-workflow" "tdd-workflow" "$SKILLS"
check "скилл prd-authoring" "prd-authoring" "$SKILLS"

echo
printf 'итого провалено: %d\n' "$FAILED"
[[ "$FAILED" -eq 0 ]]