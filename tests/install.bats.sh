set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAKE_CONFIG="$(mktemp -d /tmp/harness-test-XXXX)"
trap 'rm -rf "$FAKE_CONFIG"' EXIT

PASS=0
FAIL=0

check() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == *"$expected"* ]]; then
        printf '  ok   %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL %s\n       ожидал: %s\n       получил: %s\n' "$label" "$expected" "$actual"
        FAIL=$((FAIL + 1))
    fi
}

check_absent() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        printf '  ok   %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL %s\n       не ожидалось: %s\n' "$label" "$needle"
        FAIL=$((FAIL + 1))
    fi
}

echo "== пустой конфиг =="
mkdir -p "$FAKE_CONFIG"
OPENCODE_CONFIG_DIR="$FAKE_CONFIG" "$REPO_DIR/install.sh" >/dev/null

check "правила на месте" "$FAKE_CONFIG/AGENTS.md" "$(find "$FAKE_CONFIG" -name AGENTS.md | head -1)"
check "implementer установлен" "You implement changes" "$(cat "$FAKE_CONFIG/agent/implementer.md" 2>&1)"
check "reviewer установлен" "strict reviewer" "$(cat "$FAKE_CONFIG/agent/reviewer.md" 2>&1)"
check "команда prd" "Write a PRD for the following" "$(cat "$FAKE_CONFIG/command/prd.md" 2>&1)"
check "скилл tdd-workflow" "TDD workflow" "$(cat "$FAKE_CONFIG/skill/tdd-workflow/SKILL.md" 2>&1)"
check "скилл prd-authoring" "PRD first" "$(cat "$FAKE_CONFIG/skill/prd-authoring/SKILL.md" 2>&1)"
check "model прописан" "opencode/big-pickle" "$(cat "$FAKE_CONFIG/opencode.json")"
check "default_agent прописан" "implementer" "$(cat "$FAKE_CONFIG/opencode.json")"

echo
echo "== конфиг с провайдером и секретом =="
T2="$(mktemp -d /tmp/harness-test2-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2"' EXIT
mkdir -p "$T2/agent" "$T2/skill/legacy-skill"
cat > "$T2/opencode.json" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "some/other-model",
  "provider": {
    "openai": { "options": { "apiKey": "sk-SECRET-KEEP-ME" } },
    "lmstudio": { "npm": "@ai-sdk/openai", "name": "LM Studio" }
  },
  "mcp": { "playwright": { "type": "local", "command": ["npx", "-y", "@playwright/mcp"] } }
}
JSON
echo "прежнее правило" > "$T2/AGENTS.md"
echo "устаревший агент" > "$T2/agent/stale.md"
echo "устаревший скилл" > "$T2/skill/legacy-skill/SKILL.md"

OPENCODE_CONFIG_DIR="$T2" "$REPO_DIR/install.sh" >/dev/null

RESULT="$(cat "$T2/opencode.json")"
check "секрет провайдера сохранён" "sk-SECRET-KEEP-ME" "$RESULT"
check "второй провайдер сохранён" "lmstudio" "$RESULT"
check "mcp-конфиг сохранён" "playwright" "$RESULT"
check "model переопределён харнесом" "opencode/big-pickle" "$RESULT"
check_absent "чужой model не остался" "some/other-model" "$RESULT"
check "JSON валиден" "" "$(python3 -c "import json,sys; json.load(open('$T2/opencode.json'))" 2>&1)"

check "прежнее правило в бэкапе" "прежнее правило" \
    "$(cat "$T2"/backup-*/AGENTS.md 2>&1)"
check "прежний opencode.json в бэкапе" "sk-SECRET-KEEP-ME" \
    "$(cat "$T2"/backup-*/opencode.json 2>&1)"
check "прежнее правило перезаписано" "TDD is mandatory" "$(cat "$T2/AGENTS.md")"

echo
echo "== идемпотентность =="
OPENCODE_CONFIG_DIR="$T2" "$REPO_DIR/install.sh" >/dev/null
OPENCODE_CONFIG_DIR="$T2" "$REPO_DIR/install.sh" >/dev/null
check "повторный запуск не ломает JSON" "" \
    "$(python3 -c "import json; json.load(open('$T2/opencode.json'))" 2>&1)"
check "секрет пережил три запуска" "sk-SECRET-KEEP-ME" "$(cat "$T2/opencode.json")"

echo
echo "== uninstall =="
T4="$(mktemp -d /tmp/harness-test4-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T3" "$T4"' EXIT
mkdir -p "$T4"
cat > "$T4/opencode.json" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "some/other-model",
  "provider": { "openai": { "options": { "apiKey": "sk-SECRET-KEEP-ME" } } }
}
JSON
echo "мои заметки" > "$T4/mynotes.md"

OPENCODE_CONFIG_DIR="$T4" "$REPO_DIR/install.sh" >/dev/null
check "перед сносом правила есть" "$T4/AGENTS.md" "$(find "$T4" -maxdepth 1 -name AGENTS.md)"
check "перед сносом провайдер цел" "sk-SECRET-KEEP-ME" "$(cat "$T4/opencode.json")"

OPENCODE_CONFIG_DIR="$T4" "$REPO_DIR/uninstall.sh" >/dev/null

check_absent "правила убраны" "$T4/AGENTS.md" "$(find "$T4" -maxdepth 1 -name AGENTS.md)"
check_absent "implementer убран" "implementer.md" "$(find "$T4/agent" -name 'implementer.md' 2>&1)"
check_absent "скилл убран" "tdd-workflow" "$(find "$T4/skill" -maxdepth 1 -name 'tdd-workflow' 2>&1)"
check "чужой файл не тронут" "мои заметки" "$(cat "$T4/mynotes.md" 2>&1)"
check "секрет провайдера пережил снос" "sk-SECRET-KEEP-ME" "$(cat "$T4/opencode.json")"
check_absent "default_agent убран" "implementer" "$(cat "$T4/opencode.json")"
check "JSON валиден после сноса" "" \
    "$(python3 -c "import json; json.load(open('$T4/opencode.json'))" 2>&1)"
check "повторный снос не падает" "0" \
    "$(OPENCODE_CONFIG_DIR="$T4" "$REPO_DIR/uninstall.sh" >/dev/null 2>&1; echo $?)"

echo
echo "== битый вход =="
T3="$(mktemp -d /tmp/harness-test3-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T3"' EXIT
mkdir -p "$T3"
BROKEN='{ "model": '
printf '%s' "$BROKEN" > "$T3/opencode.json"

ERR="$(OPENCODE_CONFIG_DIR="$T3" "$REPO_DIR/install.sh" 2>&1)" && RC=0 || RC=$?
check "битый JSON валит установку" "1" "$RC"
check "причина названа" "не является валидным JSON" "$ERR"
check "битый файл не затёрт" "$BROKEN" "$(cat "$T3/opencode.json")"

echo
echo "== нет opencode =="
T5="$(mktemp -d /tmp/harness-test5-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T3" "$T5"' EXIT
mkdir -p "$T5"
NARROW_PATH="$(dirname "$(command -v python3)"):/usr/bin:/bin"

ERR="$(env PATH="$NARROW_PATH" OPENCODE_CONFIG_DIR="$T5" "$REPO_DIR/install.sh" 2>&1)" && RC=0 || RC=$?
check "нет opencode валит установку" "1" "$RC"
check "причина названа" "opencode не найден" "$ERR"
check "ссылка на документацию дана" "opencode.ai/docs" "$ERR"
check_absent "бэкап не создан" "backup-" "$(ls -A "$T5")"
check_absent "правила не скопированы" "AGENTS.md" "$(ls -A "$T5")"

echo
printf 'итого: %d ok, %d провалено\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]