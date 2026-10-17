---
name: python-reproducibility
description: Use for Python scripts, pytest, numerical analysis, notebooks, packaging and CLI utilities.
---

# Python reproducibility

## Procedure

- Check existing project structure and dependencies before adding new packages.
- Prefer standard library for small utilities; avoid unnecessary classes and abstraction layers.
- Add focused pytest tests for observable behavior, failures and regressions.
- Use deterministic seeds, explicit environments and pinned dependency constraints when reproducibility matters.
- Run the smallest relevant test first, then broader tests; distinguish not-run from passed.
- For notebooks separate reusable functions from display/plotting and document expected inputs.

## Completion report

Summarize reused code, files changed, validation performed, unverified assumptions, and any remaining risks.
