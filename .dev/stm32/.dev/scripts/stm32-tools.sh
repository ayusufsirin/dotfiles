#!/usr/bin/env bash
set -euo pipefail
source /usr/local/share/stm32-dev/stm32-env.sh

echo "STM32 store: ${STM32_STORE}"
echo
printf "%-22s %s\n" "Active project:" "${STM32_PROJECT_NAME:-<none>}"
printf "%-22s %s\n" "MCU:" "${STM32_MCU:-<none>}"
printf "%-22s %s\n" "CubeMX requested:" "${STM32_CUBEMX_VERSION:-<none>}"
printf "%-22s %s\n" "FW requested:" "${STM32_FW_PACKAGE:-<none>}"
printf "%-22s %s\n" "CubeCLT requested:" "${STM32_CUBECLT_VERSION:-<none>}"
echo

for kind in cubemx cubeclt cubeprogrammer; do
    echo "${kind}:"
    if [[ -d "${STM32_TOOLS}/${kind}" ]]; then
        find "${STM32_TOOLS}/${kind}" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null | sort -V || true
    fi
done

echo "firmware repository:"
if [[ -d "${STM32_REPOSITORY}" ]]; then
    find "${STM32_REPOSITORY}" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null | sort -V || true
fi
