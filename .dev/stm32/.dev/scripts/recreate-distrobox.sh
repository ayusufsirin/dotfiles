#!/usr/bin/env bash
set -euo pipefail
DEV_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

distrobox stop stm32-dev >/dev/null 2>&1 || true
distrobox rm -f stm32-dev >/dev/null 2>&1 || true
distrobox assemble create --file "${DEV_DIR}/distrobox.ini"

echo "Recreated stm32-dev from localhost/stm32-dev:local."
echo "The persistent STM32 store under ~/.local/share/stm32-dev was not touched."
