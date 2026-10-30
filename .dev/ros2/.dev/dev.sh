#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MODE="${1:?Usage: dev.sh build|test|exec [args...]}"
shift

case "$MODE" in
build | test | exec) ;;
*)
  echo "Unknown command: $MODE" >&2
  exit 2
  ;;
esac

cd "$ROOT"
source /opt/ros/humble/setup.bash

case "$MODE" in
  build)
    colcon build "$@" \
      --symlink-install \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    ;;
  test)
    if [[ -f install/setup.bash ]]; then
      source install/setup.bash
    fi
    colcon test "$@"
    ;;
  exec)
    if [[ -f install/setup.bash ]]; then
      source install/setup.bash
    fi
    exec "$@"
    ;;
esac