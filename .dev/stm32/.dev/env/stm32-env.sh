#!/usr/bin/env bash
# Source this file. It is also suitable as CLion's toolchain environment file.

# Distrobox shares the host HOME, while CLion containers should bind the same
# host directory to /opt/stm32. Prefer that fixed mount when present.
if [[ -d /opt/stm32 ]]; then
    export STM32_STORE=/opt/stm32
else
    export STM32_STORE="${HOME}/.local/share/stm32-dev"
fi

export STM32_TOOLS="${STM32_STORE}/tools"
export STM32_REPOSITORY="${STM32_STORE}/repository"
export STM32_PROFILES="${STM32_STORE}/profiles"

# Load the active profile if one exists.
if [[ -f "${STM32_PROFILES}/active.env" ]]; then
    # shellcheck disable=SC1090
    source "${STM32_PROFILES}/active.env"
fi

# Derive tool roots from selected versions.
if [[ -n "${STM32_CUBEMX_VERSION:-}" ]]; then
    export STM32_CUBEMX_ROOT="${STM32_TOOLS}/cubemx/${STM32_CUBEMX_VERSION}"
fi

if [[ -n "${STM32_CUBECLT_VERSION:-}" ]]; then
    export STM32_CUBECLT_ROOT="${STM32_TOOLS}/cubeclt/${STM32_CUBECLT_VERSION}"
fi

if [[ -n "${STM32_CUBEPROGRAMMER_VERSION:-}" ]]; then
    export STM32_CUBEPROGRAMMER_ROOT="${STM32_TOOLS}/cubeprogrammer/${STM32_CUBEPROGRAMMER_VERSION}"
fi

# Add common executable locations if they exist.
for d in \
    "${STM32_CUBEMX_ROOT:-}" \
    "${STM32_CUBEMX_ROOT:-}/bin" \
    "${STM32_CUBECLT_ROOT:-}/bin" \
    "${STM32_CUBECLT_ROOT:-}/GNU-tools-for-STM32/bin" \
    "${STM32_CUBECLT_ROOT:-}/STLink-gdb-server/bin" \
    "${STM32_CUBECLT_ROOT:-}/STM32CubeProgrammer/bin" \
    "${STM32_CUBEPROGRAMMER_ROOT:-}/bin"
do
    [[ -d "$d" ]] && export PATH="$d:$PATH"
done

# Generic fallback compiler from Ubuntu.
export STM32_FALLBACK_GCC=/usr/bin/arm-none-eabi-gcc
export STM32_FALLBACK_GXX=/usr/bin/arm-none-eabi-g++
