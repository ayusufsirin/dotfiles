---
name: container-dev-workflows
description: Use for Docker, Distrobox, Podman, multi-architecture ROS images and host IDE/container toolchains.
---

# Container development workflows

## Procedure

- Identify host/container boundaries, architecture, volumes, user IDs, GPU/USB needs and network assumptions.
- Prefer reproducible Dockerfiles and project-local definitions over manual container mutation.
- Do not duplicate host GUI/IDE installations inside every container without a concrete need.
- Avoid privileged containers and broad device permissions unless justified; explain security tradeoffs.
- Verify toolchain and dependency versions inside the target container, not just on the host.
- Provide exact build/run commands and describe which tests were actually executed.

## Completion report

Summarize reused code, files changed, validation performed, unverified assumptions, and any remaining risks.
