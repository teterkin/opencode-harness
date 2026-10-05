#!/usr/bin/env bash
# Установить харнесс в ~/.config/opencode.
#
# Копирует правила, агентов, команды и скиллы в конфиг opencode.
# Права провайдера и ключи не трогает: opencode.json накладывается
# поверх существующего, сохраняя provider и permission.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"

info() { printf '  %s\n' "$1"; }
fail() { printf 'ошибка: %s\n' "$1" >&2; exit 1; }

[[ -d "$REPO_DIR/agents" ]] || fail "не найдена папка agents рядом с install.sh"

command -v opencode >/dev/null 2>&1 \
    || fail "opencode не найден в PATH. Установи его: https://opencode.ai/docs/#install"

command -v python3 >/dev/null 2>&1 \
    || fail "python3 не найден в PATH. Он нужен, чтобы наложить opencode.json: https://www.python.org/downloads/"

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
cp "$REPO_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
cp "$REPO_DIR"/agents/*.md "$CONFIG_DIR/agent/"
cp "$REPO_DIR"/commands/*.md "$CONFIG_DIR/command/"
for skill_dir in "$REPO_DIR"/skills/*/; do
    name="$(basename "$skill_dir")"
    rm -rf "${CONFIG_DIR:?}/skill/$name"
    cp -R "$skill_dir" "$CONFIG_DIR/skill/$name"
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

with open(target_path, "w") as handle:
    json.dump(merged, handle, indent=2, ensure_ascii=False)
    handle.write("\n")
PY
info "opencode.json обновлён: model, default_agent, permission; провайдер и mcp сохранены"

printf '\nУстановлено в %s\n' "$CONFIG_DIR"
printf 'Выйди из opencode и запусти заново — конфиг читается только при старте.\n\n'
printf 'Проверить:\n'
printf '  opencode debug config\n'
printf '  opencode debug skill\n'
printf '  opencode debug agent implementer\n'