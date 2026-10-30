#!/usr/bin/env bash
set -euo pipefail

systemctl --user enable --now podman.socket
SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"

echo "Podman socket is enabled."
echo "CLion Engine API socket:"
echo "  unix://${SOCK}"
