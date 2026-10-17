---
name: control-numerics
description: Use for SLAM, estimation, UAV control, MPC, INDI, geometric control, numerical optimization and simulation code.
---

# Control and numerical engineering

## Procedure

- Write governing equations, coordinate frames, units, assumptions and sampling period before code changes.
- Preserve precision through intermediate calculations; choose tolerances from physical and numerical scales.
- Check discretization, conditioning, singularities, saturation, constraints and stability assumptions.
- Prefer a minimal reference implementation and deterministic tests before optimization.
- Compare against analytical cases, invariants and baseline trajectories; quantify error and runtime.
- Do not equate simulation success with flight safety or hardware validation.

## Completion report

Summarize reused code, files changed, validation performed, unverified assumptions, and any remaining risks.
