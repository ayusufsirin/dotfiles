#!/usr/bin/env bash
set -euo pipefail

STORE="${HOME}/.local/share/stm32-dev"

mkdir -p \
  "${STORE}/tools/cubemx" \
  "${STORE}/tools/cubeclt" \
  "${STORE}/tools/cubeprogrammer" \
  "${STORE}/repository" \
  "${STORE}/profiles" \
  "${STORE}/downloads"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

if [[ ! -f "${STORE}/profiles/Cube_v2.env" ]]; then
    cp "${DEV_DIR}/profiles/Cube_v2.env.example" \
       "${STORE}/profiles/Cube_v2.env"
fi

ln -sfn Cube_v2.env "${STORE}/profiles/active.env"

echo "STM32 persistent store:"
echo "  ${STORE}"
echo
echo "Active profile:"
echo "  ${STORE}/profiles/Cube_v2.env"
