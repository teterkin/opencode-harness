#!/usr/bin/env bash
# Удалить харнесс из ~/.config/opencode.
#
# Оставляет на месте opencode.json, provider, mcp и всё, чем ты
# пользовался до установки. Удаляет только то, что перечислено в манифесте
# установки. Бэкапы (backup-*) не трогает.

set -euo pipefail

CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
MANIFEST="$CONFIG_DIR/harness-installed.txt"

info() { printf '  %s\n' "$1"; }

removed=0

remove_path() {
    local rel="$1"
    [[ -n "$rel" ]] || return 0
    case "$rel" in
        /* | *..*)
            info "пропущен подозрительный путь: $rel"
            return 0
            ;;
    esac
    if [[ -d "$CONFIG_DIR/$rel" ]]; then
        rm -rf "${CONFIG_DIR:?}/$rel"
        info "удалён $rel"
        removed=$((removed + 1))
    elif [[ -f "$CONFIG_DIR/$rel" ]]; then
        rm -f "$CONFIG_DIR/$rel"
        info "удалён $rel"
        removed=$((removed + 1))
    fi
}

if [[ -f "$MANIFEST" ]]; then
    while IFS= read -r rel; do
        remove_path "$rel"
    done < "$MANIFEST"
    rm -f "$MANIFEST"
    info "манифест установки удалён"
else
    # 1.0.0 ставился без манифеста: убираем известный набор файлов.
    remove_path "AGENTS.md"
    for name in implementer plan reviewer; do
        remove_path "agent/$name.md"
    done
    for name in prd tdd review; do
        remove_path "command/$name.md"
    done
    for name in prd-authoring tdd-workflow; do
        remove_path "skill/$name"
    done
fi

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
