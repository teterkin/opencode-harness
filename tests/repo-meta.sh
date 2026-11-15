#!/usr/bin/env bash
# Проверить метаданные репозитория на GitHub.
#
# В run.sh не входит: нужны сеть и авторизация gh.
# Коды выхода: 0 — всё в порядке, 1 — есть проблемы, 2 — нет gh или авторизации,
# 3 — нет python3.

set -uo pipefail

FAILED=0

command -v gh >/dev/null 2>&1 \
    || { printf 'ошибка: gh не найден в PATH. Установи GitHub CLI: https://cli.github.com\n' >&2; exit 2; }

command -v python3 >/dev/null 2>&1 \
    || { printf 'ошибка: python3 не найден в PATH\n' >&2; exit 3; }

if ! META="$(gh repo view --json description,homepageUrl,repositoryTopics,visibility 2>/dev/null)"; then
    printf 'ошибка: gh не смог прочитать репозиторий. Проверь авторизацию: gh auth status\n' >&2
    exit 2
fi

printf '== метаданные репозитория ==\n'

python3 - "$META" <<'PY' || FAILED=1
import json
import re
import sys

meta = json.loads(sys.argv[1])
failed = 0
TOPIC = re.compile(r"^[a-z0-9][a-z0-9-]*$")


def ok(label):
    print("  ok   " + label)


def bad(label):
    global failed
    failed += 1
    print("  FAIL " + label)


description = (meta.get("description") or "").strip()
if not description:
    bad("description пустой")
elif len(description) > 350:
    bad("description длиннее 350 символов (%d)" % len(description))
elif description != description.strip("\"'"):
    bad("description в кавычках")
else:
    ok("description заполнен (%d символов)" % len(description))

topics = [(item or {}).get("name", "") for item in (meta.get("repositoryTopics") or [])]
if len(topics) < 5:
    bad("topics меньше пяти (%d)" % len(topics))
elif len(topics) > 10:
    bad("topics больше десяти (%d)" % len(topics))
else:
    ok("topics: %d штук" % len(topics))
broken = [name for name in topics if not TOPIC.match(name)]
if broken:
    bad("topics не в kebab-case: " + ", ".join(broken))
else:
    ok("topics в нижнем регистре и kebab-case")
duplicates = sorted({name for name in topics if topics.count(name) > 1})
if duplicates:
    bad("topics повторяются: " + ", ".join(duplicates))
else:
    ok("topics без дублей")

homepage = (meta.get("homepageUrl") or "").strip()
if homepage and not homepage.startswith("https://"):
    bad("homepage не https: " + homepage)
else:
    ok("homepage пустой или https")

ok("visibility: " + (meta.get("visibility") or "неизвестна"))

raise SystemExit(1 if failed else 0)
PY

if [[ "$FAILED" -ne 0 ]]; then
    printf '\nитого: есть проблемы. Заполнить: gh repo edit --description "..." --add-topic <topic>\n'
    exit 1
fi

printf '\nитого: ok\n'
