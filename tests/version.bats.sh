set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-}"

PASS=0
FAIL=0

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

check() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == *"$expected"* ]]; then
        printf '  ok   %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL %s\n       ожидал вхождение: %s\n       получил: %s\n' "$label" "$expected" "${actual:0:200}"
        FAIL=$((FAIL + 1))
    fi
}

echo "== VERSION =="
if [[ -f "$REPO_DIR/VERSION" ]]; then
    RAW="$(cat "$REPO_DIR/VERSION")"
    VALUE="$(printf '%s' "$RAW" | tr -d '[:space:]')"
    printf '  ok   VERSION существует\n'
    PASS=$((PASS + 1))
else
    VALUE=""
    printf '  FAIL VERSION не найден\n'
    FAIL=$((FAIL + 1))
fi

if [[ "$VALUE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '  ok   VERSION в формате SemVer\n'
    PASS=$((PASS + 1))
else
    printf '  FAIL VERSION не SemVer: [%s]\n' "$VALUE"
    FAIL=$((FAIL + 1))
fi

echo
echo "== CHANGELOG =="
TOP="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$REPO_DIR/CHANGELOG.md" 2>/dev/null \
    | tr -d '#[] ')"
check_eq "верхняя версия в CHANGELOG = VERSION" "$VALUE" "$TOP"
check "есть раздел Unreleased" "## [Unreleased]" "$(cat "$REPO_DIR/CHANGELOG.md" 2>&1)"

echo
echo "== тег =="
if git -C "$REPO_DIR" rev-parse -q --verify "refs/tags/v$VALUE" >/dev/null 2>&1; then
    check_eq "тег v$VALUE аннотированный" "tag" \
        "$(git -C "$REPO_DIR" cat-file -t "v$VALUE" 2>&1)"
else
    if [[ "$MODE" == "--tag" ]]; then
        printf '  FAIL тег v%s отсутствует\n' "$VALUE"
        FAIL=$((FAIL + 1))
    else
        printf '  ok   тег v%s ещё не создан (режим без --tag)\n' "$VALUE"
        PASS=$((PASS + 1))
    fi
fi

echo
printf 'итого: %d ok, %d провалено\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
