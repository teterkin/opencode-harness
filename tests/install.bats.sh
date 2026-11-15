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

check_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        printf '  ok   %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL %s\n       ожидал: [%s]\n       получил: [%s]\n' "$label" "$expected" "$actual"
        FAIL=$((FAIL + 1))
    fi
}

echo "== пустой конфиг =="
mkdir -p "$FAKE_CONFIG"
OUT="$(OPENCODE_CONFIG_DIR="$FAKE_CONFIG" "$REPO_DIR/install.sh" 2>&1)"

check "правила на месте" "$FAKE_CONFIG/AGENTS.md" "$(find "$FAKE_CONFIG" -name AGENTS.md | head -1)"
check "implementer установлен" "You implement changes" "$(cat "$FAKE_CONFIG/agent/implementer.md" 2>&1)"
check "reviewer установлен" "strict reviewer" "$(cat "$FAKE_CONFIG/agent/reviewer.md" 2>&1)"
check "команда prd" "Write a PRD for the following" "$(cat "$FAKE_CONFIG/command/prd.md" 2>&1)"
check "скилл tdd-workflow" "TDD workflow" "$(cat "$FAKE_CONFIG/skill/tdd-workflow/SKILL.md" 2>&1)"
check "скилл tdd: исходное состояние" "Precondition" "$(cat "$FAKE_CONFIG/skill/tdd-workflow/SKILL.md" 2>&1)"
check "скилл tdd: чувствительность" "Sensitivity check" "$(cat "$FAKE_CONFIG/skill/tdd-workflow/SKILL.md" 2>&1)"
check "скилл tdd: известный дефект" "xfail" "$(cat "$FAKE_CONFIG/skill/tdd-workflow/SKILL.md" 2>&1)"
check "скилл prd-authoring" "PRD first" "$(cat "$FAKE_CONFIG/skill/prd-authoring/SKILL.md" 2>&1)"
check "скилл prd: источники и допущения" "Sources and assumptions" \
    "$(cat "$FAKE_CONFIG/skill/prd-authoring/SKILL.md" 2>&1)"
check "скилл prd: docs/prd" "docs/prd/" "$(cat "$FAKE_CONFIG/skill/prd-authoring/SKILL.md" 2>&1)"
check "скилл project-kit" "Documentation baseline" \
    "$(cat "$FAKE_CONFIG/skill/project-kit/SKILL.md" 2>&1)"
check "команда release" "VERSION" "$(cat "$FAKE_CONFIG/command/release.md" 2>&1)"
check "правило: проверка git на старте задачи" "git rev-parse --is-inside-work-tree" \
    "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: авто git init" "not a git repository, initialize it" \
    "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: без спроса" '`git init`' "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: ветки" "feat/<slug>" "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: SemVer" "MAJOR.MINOR.PATCH" "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: CHANGELOG в релизе" "CHANGELOG.md" "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: docs baseline" "docs/prd/<slug>.md" "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: каркас проектного AGENTS.md" "required core" \
    "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: проверки проекта" "typecheck" "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: язык общения" "Reply in the language the user writes in" \
    "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: doctor" "tests/doctor.sh" "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: MCP по умолчанию выключен" "MCP servers default to off" \
    "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: MCP disabled в глобальном конфиге" '"disabled": true' \
    "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: MCP включается проектным конфигом" "opencode.jsonc" \
    "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "правило: MCP не через policies" "mcp.use" \
    "$(cat "$FAKE_CONFIG/AGENTS.md")"
check "model прописан" "opencode/big-pickle" "$(cat "$FAKE_CONFIG/opencode.json")"
check "default_agent прописан" "implementer" "$(cat "$FAKE_CONFIG/opencode.json")"
check "opencode.json: формат v2 (permissions)" '"permissions"' "$(cat "$FAKE_CONFIG/opencode.json")"
check_absent "opencode.json: нет deprecated permission" '"permission":' "$(cat "$FAKE_CONFIG/opencode.json")"
check "implementer: формат v2 (permissions)" "permissions:" "$(cat "$FAKE_CONFIG/agent/implementer.md")"
check_absent "implementer: нет deprecated permission" "permission:" "$(cat "$FAKE_CONFIG/agent/implementer.md")"
check "implementer: git merge запрещён" "git merge*" "$(cat "$FAKE_CONFIG/agent/implementer.md")"
check "reviewer: отдельная модель" "model: opencode/deepseek-v4-pro#high" "$(cat "$FAKE_CONFIG/agent/reviewer.md")"
check "reviewer: потолок шагов" "steps: 20" "$(cat "$FAKE_CONFIG/agent/reviewer.md")"
check_absent "в подсказках нет opencode debug skill" "debug skill" "$OUT"
check_absent "в подсказках нет opencode debug agent" "debug agent" "$OUT"

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
check_eq "JSON валиден" "" "$(python3 -c "import json,sys; json.load(open('$T2/opencode.json'))" 2>&1)"

check "прежнее правило в бэкапе" "прежнее правило" \
    "$(cat "$T2"/backup-*/AGENTS.md 2>&1)"
check "прежний opencode.json в бэкапе" "sk-SECRET-KEEP-ME" \
    "$(cat "$T2"/backup-*/opencode.json 2>&1)"
check "прежнее правило сохранено" "прежнее правило" "$(cat "$T2/AGENTS.md")"
check "правила харнесса добавлены" "TDD is mandatory" "$(cat "$T2/AGENTS.md")"
check_eq "блок харнесса один" "1" "$(grep -c 'harness:begin' "$T2/AGENTS.md")"

echo
echo "== идемпотентность =="
OPENCODE_CONFIG_DIR="$T2" "$REPO_DIR/install.sh" >/dev/null
OPENCODE_CONFIG_DIR="$T2" "$REPO_DIR/install.sh" >/dev/null
check_eq "повторный запуск не ломает JSON" "" \
    "$(python3 -c "import json; json.load(open('$T2/opencode.json'))" 2>&1)"
check "секрет пережил три запуска" "sk-SECRET-KEEP-ME" "$(cat "$T2/opencode.json")"
check_eq "блок харнесса не дублируется" "1" "$(grep -c 'harness:begin' "$T2/AGENTS.md")"
check "правка пользователя пережила повторные прогоны" "прежнее правило" "$(cat "$T2/AGENTS.md")"

echo
echo "== миграция AGENTS.md без маркеров =="
T12="$(mktemp -d /tmp/harness-test12-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T4" "$T8" "$T12"' EXIT
mkdir -p "$T12"
python3 - "$REPO_DIR/AGENTS.md" "$T12/AGENTS.md" <<'PY'
import sys

text = open(sys.argv[1], encoding="utf-8").read()
text = text.replace("<!-- harness:begin -->\n", "", 1)
text = text.replace("<!-- harness:end -->\n", "", 1)
open(sys.argv[2], "w", encoding="utf-8").write(text)
PY
OPENCODE_CONFIG_DIR="$T12" "$REPO_DIR/install.sh" >/dev/null
check_eq "старый файл получил ровно один блок" "1" "$(grep -c 'harness:begin' "$T12/AGENTS.md")"
check_eq "правила не задвоились" "1" "$(grep -c 'TDD is mandatory' "$T12/AGENTS.md")"

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
printf '\nмое правило\n' >> "$T4/AGENTS.md"

OPENCODE_CONFIG_DIR="$T4" "$REPO_DIR/uninstall.sh" >/dev/null

check "пользовательский текст пережил снос" "мое правило" "$(cat "$T4/AGENTS.md" 2>&1)"
check_absent "правила харнесса убраны" "TDD is mandatory" "$(cat "$T4/AGENTS.md" 2>&1)"
check_absent "маркеры харнесса убраны" "harness:begin" "$(cat "$T4/AGENTS.md" 2>&1)"
check_absent "implementer убран" "implementer.md" "$(find "$T4/agent" -name 'implementer.md' 2>&1)"
check_absent "скилл убран" "tdd-workflow" "$(find "$T4/skill" -maxdepth 1 -name 'tdd-workflow' 2>&1)"
check "чужой файл не тронут" "мои заметки" "$(cat "$T4/mynotes.md" 2>&1)"
check "секрет провайдера пережил снос" "sk-SECRET-KEEP-ME" "$(cat "$T4/opencode.json")"
check_absent "default_agent убран" "implementer" "$(cat "$T4/opencode.json")"
check_eq "JSON валиден после сноса" "" \
    "$(python3 -c "import json; json.load(open('$T4/opencode.json'))" 2>&1)"
check_eq "повторный снос не падает" "0" \
    "$(OPENCODE_CONFIG_DIR="$T4" "$REPO_DIR/uninstall.sh" >/dev/null 2>&1; echo $?)"

echo
echo "== манифест: снос того, что появилось после 1.0 =="
T8="$(mktemp -d /tmp/harness-test8-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T4" "$T8"' EXIT
cp -R "$REPO_DIR" "$T8/repo"
mkdir -p "$T8/repo/skills/extra-skill"
printf -- '---\nname: extra-skill\ndescription: probe\n---\n\nprobe\n' \
    > "$T8/repo/skills/extra-skill/SKILL.md"

OPENCODE_CONFIG_DIR="$T8/cfg" "$T8/repo/install.sh" >/dev/null
check "манифест создан" "harness-installed.txt" "$(ls "$T8/cfg" 2>&1)"
check "новый скилл в манифесте" "skill/extra-skill" "$(cat "$T8/cfg/harness-installed.txt" 2>&1)"

OPENCODE_CONFIG_DIR="$T8/cfg" "$T8/repo/uninstall.sh" >/dev/null
check_absent "новый скилл снесён" "extra-skill" "$(ls "$T8/cfg/skill" 2>&1)"
check_absent "агент снесён" "implementer.md" "$(ls "$T8/cfg/agent" 2>&1)"
check_absent "AGENTS.md удалён, если в нём только харнесс" "AGENTS.md" "$(ls -A "$T8/cfg" 2>&1)"
check_absent "манифест удалён" "harness-installed" "$(ls -A "$T8/cfg" 2>&1)"

echo
echo "== снос установки 1.0, когда манифеста нет =="
T9="$(mktemp -d /tmp/harness-test9-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T4" "$T8" "$T9"' EXIT
OPENCODE_CONFIG_DIR="$T9/cfg" "$REPO_DIR/install.sh" >/dev/null
rm -f "$T9/cfg/harness-installed.txt"
OPENCODE_CONFIG_DIR="$T9/cfg" "$REPO_DIR/uninstall.sh" >/dev/null
check_absent "агент снесён по старому списку" "implementer.md" "$(ls "$T9/cfg/agent" 2>&1)"
check_absent "скилл снесён по старому списку" "tdd-workflow" "$(ls "$T9/cfg/skill" 2>&1)"

echo
echo "== битый вход =="
T3="$(mktemp -d /tmp/harness-test3-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T3"' EXIT
mkdir -p "$T3"
BROKEN='{ "model": '
printf '%s' "$BROKEN" > "$T3/opencode.json"

ERR="$(OPENCODE_CONFIG_DIR="$T3" "$REPO_DIR/install.sh" 2>&1)" && RC=0 || RC=$?
check_eq "битый JSON валит установку" "1" "$RC"
check "причина названа" "не является валидным JSON" "$ERR"
check "битый файл не затёрт" "$BROKEN" "$(cat "$T3/opencode.json")"

echo
echo "== нет opencode =="
T5="$(mktemp -d /tmp/harness-test5-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T3" "$T5"' EXIT
mkdir -p "$T5"
NARROW_PATH="$(dirname "$(command -v python3)"):/usr/bin:/bin"

ERR="$(env PATH="$NARROW_PATH" OPENCODE_CONFIG_DIR="$T5" "$REPO_DIR/install.sh" 2>&1)" && RC=0 || RC=$?
check_eq "нет opencode валит установку" "1" "$RC"
check "причина названа" "opencode не найден" "$ERR"
check "ссылка на документацию дана" "opencode.ai/docs" "$ERR"
check_absent "бэкап не создан" "backup-" "$(ls -A "$T5")"
check_absent "правила не скопированы" "AGENTS.md" "$(ls -A "$T5")"

echo
echo "== нет python3 =="
T6="$(mktemp -d /tmp/harness-test6-XXXX)"
T7="$(mktemp -d /tmp/harness-test7-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T3" "$T4" "$T5" "$T6" "$T7"' EXIT
mkdir -p "$T6"
for tool in bash mkdir cp date basename rm ls env dirname opencode; do
    ln -s "$(command -v "$tool")" "$T7/$tool"
done

ERR="$(env PATH="$T7" OPENCODE_CONFIG_DIR="$T6" "$REPO_DIR/install.sh" 2>&1)" && RC=0 || RC=$?
check_eq "нет python3 валит установку" "1" "$RC"
check "причина названа" "python3 не найден" "$ERR"
check "ссылка на загрузку дана" "python.org" "$ERR"
check_absent "ошибка не про opencode" "opencode не найден" "$ERR"
check_absent "бэкап не создан" "backup-" "$(ls -A "$T6")"
check_absent "правила не скопированы" "AGENTS.md" "$(ls -A "$T6")"

echo
echo "== opencode ниже минимума =="
T10="$(mktemp -d /tmp/harness-test10-XXXX)"
T11="$(mktemp -d /tmp/harness-test11-XXXX)"
trap 'rm -rf "$FAKE_CONFIG" "$T2" "$T3" "$T4" "$T5" "$T6" "$T7" "$T9" "$T10" "$T11"' EXIT
mkdir -p "$T10"
printf '#!/bin/sh\nprintf "opencode v2.0.0\\n"\n' > "$T11/opencode"
chmod +x "$T11/opencode"

ERR="$(env PATH="$T11:$(dirname "$(command -v python3)"):/usr/bin:/bin" \
    OPENCODE_CONFIG_DIR="$T10" "$REPO_DIR/install.sh" 2>&1)" && RC=0 || RC=$?
check_eq "старая версия валит установку" "1" "$RC"
check "причина названа" "ниже минимума" "$ERR"
check "пин назван" "2.3.0" "$ERR"
check_absent "бэкап не создан" "backup-" "$(ls -A "$T10")"
check_absent "правила не скопированы" "AGENTS.md" "$(ls -A "$T10")"

echo
printf 'итого: %d ok, %d провалено\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]