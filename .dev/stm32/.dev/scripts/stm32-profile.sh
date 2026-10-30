#!/usr/bin/env bash
set -euo pipefail

STORE="${STM32_STORE:-${HOME}/.local/share/stm32-dev}"
PROFILES="${STORE}/profiles"

usage() {
    echo "Usage:"
    echo "  stm32-profile list"
    echo "  stm32-profile use <profile-name>"
    echo "  stm32-profile show"
}

cmd="${1:-}"
case "$cmd" in
    list)
        find "${PROFILES}" -maxdepth 1 -type f -name '*.env' -printf '%f\n' \
          | sed 's/\.env$//' | sort
        ;;
    use)
        name="${2:?profile name required}"
        test -f "${PROFILES}/${name}.env"
        ln -sfn "${name}.env" "${PROFILES}/active.env"
        echo "Active STM32 profile: ${name}"
        ;;
    show)
        if [[ -e "${PROFILES}/active.env" ]]; then
            readlink -f "${PROFILES}/active.env"
            cat "${PROFILES}/active.env"
        else
            echo "No active profile."
        fi
        ;;
    *)
        usage
        exit 2
        ;;
esac
