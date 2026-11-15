#!/usr/bin/env bash
# Проверить, какая версия opencode реально запускается.
#
# Сравнивает её с пином opencode.version и ищет другие установки: если рядом
# лежит версия новее, значит PATH ведёт на старый бинарь, а харнесс проверен
# не на той версии, которую ты запускаешь.
#
# Коды выхода: 0 — всё сходится, 1 — версия ниже минимума, 2 — дрейф.
# При дрейфе (2) без --no-tests дополнительно прогоняются самотесты.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIN_FILE="$REPO_DIR/opencode.version"
RUN_TESTS=1

case "${1:-}" in
    --no-tests) RUN_TESTS=0 ;;
    "") ;;
    *)
        printf 'использование: %s [--no-tests]\n' "${BASH_SOURCE[0]}" >&2
        exit 64
        ;;
esac

if [[ ! -f "$PIN_FILE" ]]; then
    printf 'ошибка: нет %s с полями tested и min\n' "$PIN_FILE" >&2
    exit 3
fi

# shellcheck disable=SC1090
. "$PIN_FILE"

PYTHON="$(command -v python3 2>/dev/null || true)"
if [[ -z "$PYTHON" ]] || ! "$PYTHON" -c 'pass' >/dev/null 2>&1; then
    printf 'ошибка: python3 не найден или не запускается (%s) — без него doctor не сравнит версии\n' \
        "${PYTHON:-нет в PATH}" >&2
    exit 3
fi

version_of() {
    "$1" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

compare_versions() {
    # Печатает -1, 0 или 1.
    python3 -c '
import sys

def key(value):
    return tuple(int(part) for part in value.split(".") if part.isdigit())

a, b = key(sys.argv[1]), key(sys.argv[2])
print(-1 if a < b else (1 if a > b else 0))
' "$1" "$2"
}

BIN="$(command -v opencode 2>/dev/null || true)"
if [[ -z "$BIN" ]]; then
    printf 'ошибка: opencode не найден в PATH. Установи: https://opencode.ai/docs/#install\n' >&2
    exit 1
fi

CURRENT="$(version_of "$BIN")"
if [[ -z "$CURRENT" ]]; then
    printf 'ошибка: %s не ответил на --version\n' "$BIN" >&2
    exit 1
fi

printf '   opencode на PATH: %s (%s)\n' "$BIN" "$CURRENT"
printf '   пин: tested %s, min %s\n' "$tested" "$min"

if [[ "$(compare_versions "$CURRENT" "$min")" == "-1" ]]; then
    printf 'ошибка: opencode %s ниже минимума %s. Обнови opencode.\n' "$CURRENT" "$min" >&2
    exit 1
fi

DRIFT=0
if [[ "$CURRENT" != "$tested" ]]; then
    printf 'дрейф: opencode %s не равна протестированной %s\n' "$CURRENT" "$tested"
    DRIFT=1
fi

DEFAULT_EXTRA=(
    "$HOME/.opencode/bin/opencode"
    /opt/homebrew/Cellar/opencode*/*/bin/opencode
    /usr/local/bin/opencode
)
EXTRA=("${DEFAULT_EXTRA[@]}")
if [[ -n "${OPENCODE_DOCTOR_EXTRA:-}" ]]; then
    for extra in $OPENCODE_DOCTOR_EXTRA; do
        EXTRA+=("$extra")
    done
fi

for candidate in "${EXTRA[@]}"; do
    [[ -x "$candidate" ]] || continue
    [[ "$candidate" -ef "$BIN" ]] && continue
    candidate_version="$(version_of "$candidate")"
    [[ -n "$candidate_version" ]] || continue
    if [[ "$(compare_versions "$candidate_version" "$CURRENT")" == "1" ]]; then
        printf 'дрейф: рядом есть новее — %s (%s)\n' "$candidate" "$candidate_version"
        printf '       PATH ведёт на старый бинарь. Слинкуй новую версию: brew link --overwrite <formula>\n'
        DRIFT=1
    fi
done

if [[ "$DRIFT" -eq 0 ]]; then
    printf '   ok: версия совпадает с пином\n'
    exit 0
fi

printf '       харнесс на этой версии не проверялся: самотесты обязательны.\n'

if [[ "$RUN_TESTS" -eq 1 ]]; then
    printf '\n== самотесты ==\n'
    bash "$REPO_DIR/tests/run.sh"
    printf '\nдрейф остаётся: приведи версию к %s или обнови пин после проверки\n' "$tested"
else
    printf '       самотесты не запускались (--no-tests)\n'
fi

exit 2
