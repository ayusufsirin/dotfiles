---
name: cpp-cmake-toolchains
description: Use for C/C++, CMake, Ninja, compile_commands.json, CLion, cross-compilation, and Distrobox toolchains.
---

# C++ CMake toolchains

## Procedure

- Inspect CMake targets, presets, compiler, sysroot and existing flags before editing.
- Prefer target-scoped CMake properties and existing targets over global flags or duplicated build logic.
- Keep IDE on host where requested; compile/debug in containers using explicit paths and toolchain mappings.
- Validate with `cmake --preset ...` or project-specific configure, then targeted build and CTest.
- Avoid introducing dependencies, generated files, or broad refactors for a localized issue.
- For cross builds distinguish host and target architecture, pkg-config paths and debugger availability.

## Completion report

Summarize reused code, files changed, validation performed, unverified assumptions, and any remaining risks.
