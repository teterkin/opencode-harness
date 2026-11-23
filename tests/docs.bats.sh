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
contains "README: семь шагов" "семи шагов" "README.md"
contains "README: ревью — один проход" "один проход, не цикл" "README.md"
contains "README: ревью — решение, а не недоделка" "Это решение, а не недоделка" "README.md"
contains "README: матрица 2.7.0" "| 2.7.0 |" "README.md"
contains "README: SAST вне ответственности" "SAST" "README.md"
contains "README: secret scanning" "Secret Scanning" "README.md"
contains "README: SCA" "SCA" "README.md"
contains "README: SAST и SCA в CI/CD" "CI/CD" "README.md"
contains "README: проверка безопасности в правилах" \
    "Заявленная проверка безопасности" "README.md"
contains "README: вендоренный код в правилах" "Вендоренный код не доверяют" \
    "README.md"
contains "workflow: отдельные согласия" "отдельного согласия" "docs/workflow.md"
contains "workflow: ревью — один проход" "один отдельный проход" "docs/workflow.md"
contains "AGENTS.md: ревью — не цикл" "Review is one separate pass, not a loop" "AGENTS.md"
contains "review: сначала находки" "do not fix anything yet" "commands/review.md"
contains "PRD 2.7: авто-цикл в non-goals" "Автоматический цикл" "docs/prd/2.7.md"

if grep -rq '/goal' "$REPO_DIR/commands"; then
    printf '  FAIL commands: /goal не используется в командах\n'
    FAIL=$((FAIL + 1))
else
    printf '  ok   commands: /goal не используется в командах\n'
    PASS=$((PASS + 1))
fi
contains "project-kit: метаданные репозитория" "Repository metadata" \
    "skills/project-kit/SKILL.md"
contains "project-kit: gh repo edit" "gh repo edit" "skills/project-kit/SKILL.md"
contains "AGENTS.md: метаданные репозитория" "Repository metadata" "AGENTS.md"

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

if grep -q 'чужой `model` переопределяется' "$REPO_DIR/README.md"; then
    printf '  FAIL README: утверждает, что установщик переопределяет model\n'
    FAIL=$((FAIL + 1))
else
    printf '  ok   README: не утверждает, что установщик переопределяет model\n'
    PASS=$((PASS + 1))
fi

echo
echo "== AGENTS.md: каркас проекта =="
contains "AGENTS.md: команды проверок" "typecheck" "AGENTS.md"
contains "AGENTS.md: секреты" "secrets" "AGENTS.md"
contains "AGENTS.md: ветки" "feat/<slug>" "AGENTS.md"

echo
echo "== AGENTS.md: вендоренный код и проверки безопасности =="
contains "AGENTS.md: вендоренный код проверяется" \
    "Vendored code and downloaded assets are verified before use" "AGENTS.md"
contains "AGENTS.md: чек-сумма при загрузке" "checksum compared at load time" \
    "AGENTS.md"
contains "AGENTS.md: версия третьего файла" \
    "Record the version of every third-party file" "AGENTS.md"
contains "AGENTS.md: без eval до проверки" \
    "Never execute fetched or vendored code" "AGENTS.md"
contains "AGENTS.md: fail closed" "fail closed" "AGENTS.md"
contains "AGENTS.md: security-проверка проекта" \
    "A security check declared by the project is one of the checks" "AGENTS.md"
contains "AGENTS.md: не подразумевать зелёным" "Never imply it is green" \
    "AGENTS.md"
contains "AGENTS.md: находка с причиной" \
    "written down once with the reason" "AGENTS.md"

RULES_COUNT="$(grep -c '^## [0-9]' "$REPO_DIR/AGENTS.md")"
if [[ "$RULES_COUNT" -eq 13 ]]; then
    printf '  ok   AGENTS.md: тринадцать правил, без новых разделов\n'
    PASS=$((PASS + 1))
else
    printf '  FAIL AGENTS.md: ожидал 13 правил, нашёл %s\n' "$RULES_COUNT"
    FAIL=$((FAIL + 1))
fi

echo
echo "== шаблоны =="
present "шаблон проектного AGENTS.md" "templates/AGENTS.md"
contains "шаблон AGENTS.md: команды" "## Commands" "templates/AGENTS.md"
contains "шаблон AGENTS.md: карта проекта" "## Project map" "templates/AGENTS.md"
present "шаблон PRD" "templates/PRD.md"
contains "шаблон PRD: критерии приёмки" "Acceptance criteria" "templates/PRD.md"
contains "шаблон PRD: источники" "Sources and assumptions" "templates/PRD.md"

echo
echo "== workflow =="
contains "workflow: проверка границы" "Проверка границы" "docs/workflow.md"
contains "workflow: соседний репозиторий" "Соседний репозиторий" "docs/workflow.md"
contains "workflow: запись вне проекта" "Запись вне проекта" "docs/workflow.md"
contains "workflow: самостоятельный коммит" "Самостоятельный коммит" "docs/workflow.md"
contains "workflow: проверка безопасности" "Проверка безопасности" \
    "docs/workflow.md"
contains "workflow: SAST в CI/CD" "SAST" "docs/workflow.md"
contains "workflow: вендоренный код" "Вендоренный" "docs/workflow.md"

echo
printf 'итого: %d ok, %d провалено\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
