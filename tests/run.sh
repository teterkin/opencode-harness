#!/usr/bin/env bash
# Прогнать все проверки харнесса.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf '== окружение ==\n'
bash "$SCRIPT_DIR/doctor.sh" --no-tests
ENV_RC=$?

printf '\n== doctor ==\n'
bash "$SCRIPT_DIR/doctor.bats.sh"
DOCTOR_RC=$?

printf '\n== install / uninstall ==\n'
bash "$SCRIPT_DIR/install.bats.sh"
INSTALL_RC=$?

printf '\n== настройка opencode ==\n'
bash "$SCRIPT_DIR/verify.sh"
VERIFY_RC=$?

printf '\n== версия ==\n'
bash "$SCRIPT_DIR/version.bats.sh"
VERSION_RC=$?

printf '\n== документация ==\n'
bash "$SCRIPT_DIR/docs.bats.sh"
DOCS_RC=$?

status() { [[ "$1" -eq 0 ]] && echo ok || echo FAIL; }

printf '\nокружение: %s, doctor: %s, установка: %s, настройка: %s, версия: %s, доки: %s\n' \
    "$(status "$ENV_RC")" "$(status "$DOCTOR_RC")" \
    "$(status "$INSTALL_RC")" "$(status "$VERIFY_RC")" \
    "$(status "$VERSION_RC")" "$(status "$DOCS_RC")"

[[ "$ENV_RC" -eq 0 && "$DOCTOR_RC" -eq 0 && "$INSTALL_RC" -eq 0 \
    && "$VERIFY_RC" -eq 0 && "$VERSION_RC" -eq 0 && "$DOCS_RC" -eq 0 ]]
