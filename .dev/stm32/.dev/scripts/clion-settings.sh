#!/usr/bin/env bash
set -euo pipefail

STORE="${HOME}/.local/share/stm32-dev"
SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"

cat <<EOF
CLion settings

Docker/Podman connection:
  Engine API URL:
    unix://${SOCK}

Docker toolchain image:
  localhost/stm32-dev:local

Container Settings volume binding:
  ${STORE}:/opt/stm32:rw

Toolchain environment file inside the image:
  /usr/local/share/stm32-dev/stm32-env.sh

The image provides the generic compiler/build/debug dependencies.
The volume provides persistent STM32CubeMX / CubeCLT / CubeProgrammer
versions and the STM32Cube firmware repository.
EOF
