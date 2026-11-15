#!/usr/bin/env bash
# Установить харнесс в ~/.config/opencode.
#
# Копирует правила, агентов, команды и скиллы в конфиг opencode.
# Права провайдера и ключи не трогает: opencode.json накладывается
# поверх существующего, сохраняя provider и permissions.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"

DRY_RUN=0
case "${1:-}" in
    --dry-run) DRY_RUN=1 ;;
    "") ;;
    *)
        printf 'использование: %s [--dry-run]\n' "${BASH_SOURCE[0]}" >&2
        exit 64
        ;;
esac

info() { printf '  %s\n' "$1"; }
fail() { printf 'ошибка: %s\n' "$1" >&2; exit 1; }

[[ -d "$REPO_DIR/agents" ]] || fail "не найдена папка agents рядом с install.sh"

command -v opencode >/dev/null 2>&1 \
    || fail "opencode не найден в PATH. Установи его: https://opencode.ai/docs/#install"

command -v python3 >/dev/null 2>&1 \
    || fail "python3 не найден в PATH. Он нужен, чтобы наложить opencode.json: https://www.python.org/downloads/"

PIN_FILE="$REPO_DIR/opencode.version"
[[ -f "$PIN_FILE" ]] || fail "не найден $PIN_FILE с полями tested и min"
# shellcheck disable=SC1090
. "$PIN_FILE"
OPENCODE_VERSION="$(opencode --version 2>/dev/null \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
[[ -n "$OPENCODE_VERSION" ]] \
    || fail "opencode не ответил на --version. Проверь установку: https://opencode.ai/docs/#install"
if python3 - "$OPENCODE_VERSION" "$min" <<'PY'
import sys

def key(value):
    return tuple(int(part) for part in value.split(".") if part.isdigit())

raise SystemExit(0 if key(sys.argv[1]) >= key(sys.argv[2]) else 1)
PY
then
    :
else
    fail "opencode $OPENCODE_VERSION ниже минимума $min. Обнови opencode: https://opencode.ai/docs/#install"
fi

if [[ -f "$CONFIG_DIR/opencode.json" ]]; then
    python3 - "$CONFIG_DIR/opencode.json" <<'PY'
import json
import sys

try:
    with open(sys.argv[1]) as handle:
        json.load(handle)
except json.JSONDecodeError as error:
    sys.exit(f"ошибка: {sys.argv[1]} не является валидным JSON: {error}")
PY
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    STAGE="$(mktemp -d "${TMPDIR:-/tmp}/harness-plan-XXXXXX")"
    SNAPSHOT="$STAGE/before"
    PLANNED="$STAGE/after"
    mkdir -p "$SNAPSHOT" "$PLANNED"
    for name in AGENTS.md opencode.json agent command skill; do
        if [[ -e "$CONFIG_DIR/$name" ]]; then
            cp -R "$CONFIG_DIR/$name" "$SNAPSHOT/$name"
        fi
    done
    cp -R "$SNAPSHOT/." "$PLANNED/"
    if ! OPENCODE_CONFIG_DIR="$PLANNED" "$REPO_DIR/install.sh" >/dev/null; then
        rm -rf "$STAGE"
        exit 1
    fi
    printf 'план установки (--dry-run), ничего не изменено:\n'
    python3 - "$SNAPSHOT" "$PLANNED" <<'PY'
import json
import os
import sys

before_root, after_root = sys.argv[1], sys.argv[2]
IGNORED = {"harness-installed.txt"}


def collect(root):
    found = set()
    for base, dirs, names in os.walk(root):
        dirs[:] = [name for name in dirs if not name.startswith("backup-")]
        for name in names:
            path = os.path.join(base, name)
            rel = os.path.relpath(path, root)
            if rel.split(os.sep)[0] in IGNORED:
                continue
            found.add(rel)
    return found


def read(path):
    with open(path, "rb") as handle:
        return handle.read()


def load_config(root):
    path = os.path.join(root, "opencode.json")
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


before = collect(before_root)
after = collect(after_root)

for rel in sorted(after - before):
    print("  создать " + rel)
for rel in sorted(before - after):
    print("  удалить " + rel)
for rel in sorted(before & after):
    left = read(os.path.join(before_root, rel))
    right = read(os.path.join(after_root, rel))
    if left != right:
        print("  обновить " + rel)

old, new = load_config(before_root), load_config(after_root)
for key in sorted(set(old) | set(new)):
    if key not in old:
        print("  opencode.json: +" + key)
    elif key not in new:
        print("  opencode.json: -" + key)
    elif old[key] != new[key]:
        print("  opencode.json: ~" + key)
PY
    rm -rf "$STAGE"
    printf '\nБэкап, манифест и конфиг не изменены: это план.\n'
    exit 0
fi

if [[ -d "$CONFIG_DIR" ]]; then
    info "конфиг найден: $CONFIG_DIR"
else
    info "создаю конфиг: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

BACKUP_DIR="$CONFIG_DIR/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
info "бэкап прежних файлов: $BACKUP_DIR"

for name in AGENTS.md opencode.json; do
    if [[ -f "$CONFIG_DIR/$name" ]]; then
        cp "$CONFIG_DIR/$name" "$BACKUP_DIR/$name"
    fi
done
for dir in agent command skill; do
    if [[ -d "$CONFIG_DIR/$dir" ]]; then
        cp -R "$CONFIG_DIR/$dir" "$BACKUP_DIR/$dir"
    fi
done

mkdir -p "$CONFIG_DIR/agent" "$CONFIG_DIR/command" "$CONFIG_DIR/skill"
MANIFEST="$CONFIG_DIR/harness-installed.txt"
: > "$MANIFEST"
record() { printf '%s\n' "$1" >> "$MANIFEST"; }

merge_agents_md() {
    python3 - "$REPO_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md" <<'PY'
import sys

BEGIN = "<!-- harness:begin -->"
END = "<!-- harness:end -->"

source_path, target_path = sys.argv[1], sys.argv[2]
with open(source_path, encoding="utf-8") as handle:
    source = handle.read()

start = source.index(BEGIN)
end = source.index(END, start) + len(END)
block = source[start:end].rstrip("\n") + "\n"

try:
    with open(target_path, encoding="utf-8") as handle:
        existing = handle.read()
except FileNotFoundError:
    existing = ""

if not existing.strip():
    merged = block
elif BEGIN in existing and END in existing:
    old_start = existing.index(BEGIN)
    old_end = existing.index(END, old_start) + len(END)
    rest = existing[old_end:].lstrip("\n")
    merged = existing[:old_start] + block + ("\n" + rest if rest else "")
else:
    without_markers = source.replace(BEGIN + "\n", "", 1).replace(END + "\n", "")
    if existing.strip() == without_markers.strip():
        merged = block
    else:
        merged = block + "\n" + existing.lstrip("\n")

with open(target_path, "w", encoding="utf-8") as handle:
    handle.write(merged)
PY
}

merge_agents_md
record "AGENTS.md"
for file in "$REPO_DIR"/agents/*.md; do
    name="$(basename "$file")"
    cp "$file" "$CONFIG_DIR/agent/$name"
    record "agent/$name"
done
for file in "$REPO_DIR"/commands/*.md; do
    name="$(basename "$file")"
    cp "$file" "$CONFIG_DIR/command/$name"
    record "command/$name"
done
for skill_dir in "$REPO_DIR"/skills/*/; do
    name="$(basename "$skill_dir")"
    rm -rf "${CONFIG_DIR:?}/skill/$name"
    cp -R "$skill_dir" "$CONFIG_DIR/skill/$name"
    record "skill/$name"
    info "скилл $name"
done
info "правила, агенты и команды скопированы"

python3 - "$CONFIG_DIR/opencode.json" "$REPO_DIR/opencode.json" <<'PY'
import json
import sys

target_path, harness_path = sys.argv[1], sys.argv[2]


def deep_merge(base, overlay):
    """Overlay wins for scalars and lists, merges dicts recursively."""
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_merge(base[key], value)
        else:
            base[key] = value
    return base


with open(harness_path) as handle:
    harness = json.load(handle)

try:
    with open(target_path) as handle:
        existing = json.load(handle)
except FileNotFoundError:
    existing = {}
except json.JSONDecodeError as error:
    sys.exit(f"ошибка: {target_path} не является валидным JSON: {error}")

# Keep the user's provider, mcp, plugin and any other settings. Only the keys
# the harness owns are overwritten.
merged = deep_merge(existing, harness)

DEFAULTS = {"model": "opencode/big-pickle", "default_agent": "implementer"}
for key, value in DEFAULTS.items():
    merged.setdefault(key, value)

with open(target_path, "w") as handle:
    json.dump(merged, handle, indent=2, ensure_ascii=False)
    handle.write("\n")
PY
info "opencode.json обновлён: model, default_agent, permissions; провайдер и mcp сохранены"
info "манифест установки: $MANIFEST"

printf '\nУстановлено в %s\n' "$CONFIG_DIR"
printf 'Конфиг подхватится сам: opencode следит за файлами. Если что-то не применилось — /reload.\n\n'
printf 'Проверить:\n'
printf '  opencode api GET /api/agent\n'
printf '  opencode api GET /api/command\n'
printf '  opencode api GET /api/skill\n'