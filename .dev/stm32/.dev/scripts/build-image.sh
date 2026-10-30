#!/usr/bin/env bash
set -euo pipefail
DEV_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

podman build \
  --pull=missing \
  -t localhost/stm32-dev:local \
  -f "${DEV_DIR}/Containerfile" \
  "${DEV_DIR}"

podman image inspect localhost/stm32-dev:local \
  --format 'Built {{.RepoTags}}  {{.Id}}'
