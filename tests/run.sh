#!/usr/bin/env bash
# Прогнать все проверки харнесса.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf '== install / uninstall ==\n'
bash "$SCRIPT_DIR/install.bats.sh"
INSTALL_RC=$?

printf '\n== настройка opencode ==\n'
bash "$SCRIPT_DIR/verify.sh"
VERIFY_RC=$?

printf '\nустановка: %s, настройка: %s\n' \
    "$([[ "$INSTALL_RC" -eq 0 ]] && echo ok || echo FAIL)" \
    "$([[ "$VERIFY_RC" -eq 0 ]] && echo ok || echo FAIL)"

[[ "$INSTALL_RC" -eq 0 && "$VERIFY_RC" -eq 0 ]]