#!/usr/bin/env bash
set -euo pipefail

IMAGE=localhost/stm32-dev:local
podman run --rm "${IMAGE}" bash -lc '
set -e
for c in cmake ninja arm-none-eabi-gcc arm-none-eabi-g++ gdb-multiarch openocd clangd clang-tidy cppcheck; do
    printf "%-24s" "$c"
    command -v "$c"
done
echo
arm-none-eabi-gcc --version | head -n1
cmake --version | head -n1
openocd --version 2>&1 | head -n1
'
