#!/usr/bin/env bash

# This file is intended to be sourced.

OSA_WS_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/../.." &&
    pwd
)"

# ROS/colcon setup scripts may reference unset variables.
# Temporarily disable `set -u`, then restore the caller's state.
_ros_source_setup()
{
    local had_nounset=0

    case "$-" in
        *u*)
            had_nounset=1
            set +u
            ;;
    esac

    # shellcheck disable=SC1090
    source "$1"
    local rc=$?

    if (( had_nounset )); then
        set -u
    fi

    return "$rc"
}

if [[ -z "${ROS_DISTRO:-}" ]]; then
    if [[ -f /opt/ros/humble/setup.bash ]]; then
        _ros_source_setup /opt/ros/humble/setup.bash
    else
        echo "ROS 2 environment not found under /opt/ros/humble" >&2
        return 1
    fi
fi

if [[ -f "$OSA_WS_ROOT/install/setup.bash" ]]; then
    _ros_source_setup "$OSA_WS_ROOT/install/setup.bash"
fi

unset -f _ros_source_setup

export OSA_WS_ROOT
