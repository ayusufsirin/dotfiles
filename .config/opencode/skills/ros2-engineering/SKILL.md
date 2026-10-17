---
name: ros2-engineering
description: Use for ROS 2 nodes, packages, launch files, TF, QoS, executors, and colcon changes.
---

# ROS 2 engineering

## Procedure

- Identify ROS distribution, middleware, package layout, interfaces and target hardware before edits.
- Trace existing topics, frames, QoS profiles and executor/thread assumptions. Reuse established abstractions.
- Preserve frame conventions, timestamps, interface compatibility and lifecycle semantics.
- Prefer minimal changes with reproducible `colcon build --packages-select ...` and targeted `colcon test --packages-select ...`.
- Check TF connectivity, QoS compatibility, launch parameters, namespace/remapping and shutdown behavior.
- Report commands actually run separately from recommended checks. Never claim hardware validation without hardware.

## Completion report

Summarize reused code, files changed, validation performed, unverified assumptions, and any remaining risks.
