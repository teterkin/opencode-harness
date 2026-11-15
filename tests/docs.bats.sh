set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

present() {
    local label="$1" path="$2"
    if [[ -e "$REPO_DIR/$path" ]]; then
        printf '  ok   %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL %s: нет %s\n' "$label" "$path"
        FAIL=$((FAIL + 1))
    fi
}

contains() {
    local label="$1" expected="$2" path="$3"
    local actual
    actual="$(cat "$REPO_DIR/$path" 2>&1)"
    if [[ "$actual" == *"$expected"* ]]; then
        printf '  ok   %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL %s\n       ожидал в %s: %s\n' "$label" "$path" "$expected"
        FAIL=$((FAIL + 1))
    fi
}

echo "== документация =="
present "LICENSE" "LICENSE"
present "README" "README.md"
present "CHANGELOG" "CHANGELOG.md"
present "TODO" "TODO.md"
present "AGENTS.md" "AGENTS.md"
present "docs/prd" "docs/prd"
present "docs/workflow.md" "docs/workflow.md"

echo
echo "== README =="
contains "README: описание" "## Зачем нужен харнес" "README.md"
contains "README: установка" "## Установка" "README.md"
contains "README: использование" "## Как пользоваться" "README.md"
contains "README: архитектура" "## Что где лежит" "README.md"
contains "README: версии" "## Версии и совместимость" "README.md"

ORDER_CHECK="$(python3 - "$REPO_DIR/README.md" <<'PY'
import sys

required = [
    "## Зачем нужен харнес",
    "## Установка",
    "## Как пользоваться",
    "## Что где лежит",
    "## Версии и совместимость",
]
text = open(sys.argv[1], encoding="utf-8").read()
positions = [text.find(heading) for heading in required]
if -1 in positions:
    print("нет секции: " + required[positions.index(-1)])
elif positions != sorted(positions):
    print("порядок: " + ", ".join(required))
else:
    print("ok")
PY
)"
if [[ "$ORDER_CHECK" == "ok" ]]; then
    printf '  ok   README: пять секций в нужном порядке\n'
    PASS=$((PASS + 1))
else
    printf '  FAIL README: пять секций в нужном порядке (%s)\n' "$ORDER_CHECK"
    FAIL=$((FAIL + 1))
fi

contains "README: матрица 2.0.0" "| 2.0.0 |" "README.md"
contains "README: opencode 2.3.0" "2.3.0" "README.md"
contains "README: APPROVE не заменяет тесты" "APPROVE" "README.md"
contains "README: команда /release" "/release" "README.md"
contains "README: doctor" "tests/doctor.sh" "README.md"
contains "README: тринадцать правил" "Тринадцать правил" "README.md"
contains "README: граница проекта" "external_directory: ask" "README.md"
contains "README: корень репозитория" "git rev-parse --show-toplevel" "README.md"

if grep -q 'opencode debug skill\|opencode debug agent' "$REPO_DIR/README.md"; then
    printf '  FAIL README: остались команды opencode v1 (debug skill/agent)\n'
    FAIL=$((FAIL + 1))
else
    printf '  ok   README: нет команд opencode v1\n'
    PASS=$((PASS + 1))
fi

contains "README: /reload вместо перезапуска" "/reload" "README.md"

if grep -q 'запусти заново' "$REPO_DIR/README.md"; then
    printf '  FAIL README: остался совет перезапустить opencode\n'
    FAIL=$((FAIL + 1))
else
    printf '  ok   README: нет совета перезапустить opencode\n'
    PASS=$((PASS + 1))
fi

echo
echo "== AGENTS.md: каркас проекта =="
contains "AGENTS.md: команды проверок" "typecheck" "AGENTS.md"
contains "AGENTS.md: секреты" "secrets" "AGENTS.md"
contains "AGENTS.md: ветки" "feat/<slug>" "AGENTS.md"

echo
echo "== шаблоны =="
present "шаблон проектного AGENTS.md" "templates/AGENTS.md"
contains "шаблон AGENTS.md: команды" "## Commands" "templates/AGENTS.md"
contains "шаблон AGENTS.md: карта проекта" "## Project map" "templates/AGENTS.md"
present "шаблон PRD" "templates/PRD.md"
contains "шаблон PRD: критерии приёмки" "Acceptance criteria" "templates/PRD.md"
contains "шаблон PRD: источники" "Sources and assumptions" "templates/PRD.md"

echo
printf 'итого: %d ok, %d провалено\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
