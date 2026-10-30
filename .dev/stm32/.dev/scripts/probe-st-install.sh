#!/usr/bin/env bash
set -euo pipefail

STORE="${HOME}/.local/share/stm32-dev"
echo "Scanning: ${STORE}/tools"
echo

find "${STORE}/tools" -maxdepth 5 -type f -perm -u+x 2>/dev/null \
  | grep -Ei '(STM32CubeMX|STM32_Programmer|STM32CubeProgrammer|ST-LINK|arm-none-eabi-(gcc|g\+\+|gdb)$)' \
  | sort || true
