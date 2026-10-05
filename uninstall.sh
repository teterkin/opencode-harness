#!/usr/bin/env bash
# Удалить харнесс из ~/.config/opencode.
#
# Оставляет на месте opencode.json, provider, mcp и всё, чем ты
# пользовался до установки. Удаляет только файлы харнесса.
# Бэкапы (backup-*) не трогает.

set -euo pipefail

CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"

info() { printf '  %s\n' "$1"; }

removed=0

if [[ -f "$CONFIG_DIR/AGENTS.md" ]]; then
    rm -f "$CONFIG_DIR/AGENTS.md"
    info "удалён AGENTS.md"
    removed=$((removed + 1))
fi

for name in implementer plan reviewer; do
    if [[ -f "$CONFIG_DIR/agent/$name.md" ]]; then
        rm -f "$CONFIG_DIR/agent/$name.md"
        info "удалён agent/$name.md"
        removed=$((removed + 1))
    fi
done

for name in prd tdd review; do
    if [[ -f "$CONFIG_DIR/command/$name.md" ]]; then
        rm -f "$CONFIG_DIR/command/$name.md"
        info "удалён command/$name.md"
        removed=$((removed + 1))
    fi
done

for name in prd-authoring tdd-workflow; do
    if [[ -d "$CONFIG_DIR/skill/$name" ]]; then
        rm -rf "${CONFIG_DIR:?}/skill/$name"
        info "удалён skill/$name"
        removed=$((removed + 1))
    fi
done

python3 - "$CONFIG_DIR/opencode.json" <<'PY' 2>/dev/null || true
import json
import sys

path = sys.argv[1]
try:
    with open(path) as handle:
        config = json.load(handle)
except (FileNotFoundError, json.JSONDecodeError):
    raise SystemExit(0)

changed = False
if config.get("default_agent") == "implementer":
    del config["default_agent"]
    changed = True

with open(path, "w") as handle:
    json.dump(config, handle, indent=2, ensure_ascii=False)
    handle.write("\n")

if changed:
    print("  из opencode.json убран default_agent")
PY

if [[ "$removed" -eq 0 ]]; then
    printf 'Харнес не был установлен в %s\n' "$CONFIG_DIR"
else
    printf '\nУдалено файлов: %d\n' "$removed"
fi
printf 'model в opencode.json не трогал. Выйди и снова запусти opencode.\n'