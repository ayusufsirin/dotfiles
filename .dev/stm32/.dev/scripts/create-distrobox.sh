#!/usr/bin/env bash
set -euo pipefail
DEV_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if ! podman image exists localhost/stm32-dev:local; then
    echo "Missing image localhost/stm32-dev:local" >&2
    echo "Run: ${DEV_DIR}/scripts/build-image.sh" >&2
    exit 1
fi

distrobox assemble create --file "${DEV_DIR}/distrobox.ini"

echo
echo "Created stm32-dev."
echo "Enter with:"
echo "  distrobox enter stm32-dev"
