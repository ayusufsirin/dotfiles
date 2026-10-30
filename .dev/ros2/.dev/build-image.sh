#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

podman build \
  --target deps \
  --tag localhost/osa-dev:local \
  --file Dockerfile \
  .

echo "Development image built: localhost/osa-dev:local"
