set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d /tmp/harness-doctor-XXXX)"
trap 'rm -rf "$TMP"' EXIT

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

fake_opencode() {
    local dir="$1" version="$2"
    mkdir -p "$dir"
    printf '#!/bin/sh\nprintf "opencode v%s\\n"\n' "$version" > "$dir/opencode"
    chmod +x "$dir/opencode"
    printf '%s' "$dir"
}

run_doctor() {
    local path_dir="$1" extra="${2:-}"
    env PATH="$path_dir:/usr/bin:/bin" \
        OPENCODE_DOCTOR_EXTRA="$extra" \
        "$REPO_DIR/tests/doctor.sh" --no-tests 2>&1
}

echo "== версия совпадает с пином =="
BIN_A="$(fake_opencode "$TMP/a" 2.3.0)"
OUT="$(run_doctor "$BIN_A")" && RC=0 || RC=$?
check_eq "код 0" "0" "$RC"
check "версия названа" "2.3.0" "$OUT"

echo
echo "== версия ниже минимума =="
BIN_B="$(fake_opencode "$TMP/b" 2.0.0)"
OUT="$(run_doctor "$BIN_B")" && RC=0 || RC=$?
check_eq "код 1" "1" "$RC"
check "причина названа" "ниже минимума" "$OUT"
check "пин назван" "2.3.0" "$OUT"

echo
echo "== на PATH старая, рядом лежит новая =="
BIN_C="$(fake_opencode "$TMP/c" 2.3.0)"
EXTRA="$(fake_opencode "$TMP/extra" 2.4.0)/opencode"
OUT="$(run_doctor "$BIN_C" "$EXTRA")" && RC=0 || RC=$?
check_eq "код 2 (дрейф)" "2" "$RC"
check "новая версия найдена" "2.4.0" "$OUT"
check "путь новой версии назван" "$TMP/extra/opencode" "$OUT"
check "совет дан" "brew link" "$OUT"

echo
echo "== старая установка рядом дрейфом не считается =="
BIN_D="$(fake_opencode "$TMP/d" 2.3.0)"
EXTRA_OLD="$(fake_opencode "$TMP/old" 1.4.3)/opencode"
OUT="$(run_doctor "$BIN_D" "$EXTRA_OLD")" && RC=0 || RC=$?
check_eq "код 0" "0" "$RC"

echo
echo "== старый формат вывода версии =="
mkdir -p "$TMP/oldfmt"
printf '#!/bin/sh\nprintf "1.4.3\\n"\n' > "$TMP/oldfmt/opencode"
chmod +x "$TMP/oldfmt/opencode"
OUT="$(run_doctor "$TMP/oldfmt")" && RC=0 || RC=$?
check_eq "код 1" "1" "$RC"
check "версия распознана" "1.4.3" "$OUT"
check "причина названа" "ниже минимума" "$OUT"

echo
echo "== сломанный python3 =="
BIN_E="$(fake_opencode "$TMP/e" 2.3.0)"
mkdir -p "$TMP/nopy"
printf '#!/bin/sh\nexit 1\n' > "$TMP/nopy/python3"
chmod +x "$TMP/nopy/python3"
OUT="$(env PATH="$TMP/nopy:$BIN_E:/usr/bin:/bin" \
    "$REPO_DIR/tests/doctor.sh" --no-tests 2>&1)" && RC=0 || RC=$?
check_eq "код 3 (не смог сравнить)" "3" "$RC"
check "причина названа" "python3" "$OUT"
if [[ "$OUT" == *"ok: версия совпадает"* ]]; then
    printf '  FAIL ложное ok при сломанном python3\n'
    FAIL=$((FAIL + 1))
else
    printf '  ok   без ложного ok\n'
    PASS=$((PASS + 1))
fi

echo
printf 'итого: %d ok, %d провалено\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
