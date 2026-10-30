#!/usr/bin/env bash
set -euo pipefail

distrobox enter stm32-dev -- bash -lc '
source /usr/local/share/stm32-dev/stm32-env.sh
echo "container=${CONTAINER_ID:-unknown}"
echo "STM32_STORE=${STM32_STORE}"
echo "STM32_REPOSITORY=${STM32_REPOSITORY}"
echo "profile=${STM32_PROJECT_NAME:-none}"
echo "MCU=${STM32_MCU:-none}"
echo "CubeMX=${STM32_CUBEMX_VERSION:-not selected}"
echo "Firmware=${STM32_FW_PACKAGE:-not selected}"
echo
stm32-tools
'
