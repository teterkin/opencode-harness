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
