# OpenCode engineering workflow

## Operating principles

- Reuse and simplify existing code before introducing new implementations. Ponytail handles generic simplicity guidance; domain skills add technical constraints.
- Do not automatically delegate every task. For a small, localized change, one implementer and targeted tests are sufficient.
- For complex changes: explore existing behavior -> agree on scope -> implement minimal diff -> test -> independent review.
- Load relevant domain skills on demand; avoid loading all skills for every task.
- Preserve public interfaces, timing constraints, numerical semantics and error handling unless explicitly changing them.
- Treat external provider access and model quotas as environment-specific; do not assume catalog visibility implies authorization.

## Quality gates

1. Establish baseline: `git status --short`, existing tests, compiler/toolchain versions.
2. Inspect existing implementation and identify code that can be reused or removed.
3. Implement the smallest coherent change. Do not introduce speculative frameworks.
4. Prefer project-owned tools: clang-format, clang-tidy, CMake/CTest, Ruff, pytest and pre-commit. Never replace them with an LLM review or a bespoke generic analyzer.
5. Run cheap checks on changed files; run builds and relevant tests at task completion or CI.
6. Review `git diff --check` and `git diff --stat`; inspect behavior, not just line counts.
7. For nontrivial changes, use Ponytail review or an independent reviewer; address correctness issues before cosmetic issues.
8. State what was tested, what was not tested, and why.

## Existing tool integration

- `clangd` is an editor/LSP service, not a batch quality gate. Use `clang-tidy` for static analysis and a valid compilation database from the actual build environment.
- Use `ruff check` / `ruff format --check` for Python and `clang-format --dry-run --Werror` for C/C++.
- Do not run whole-workspace `clang-tidy` or `colcon test` after each file edit. Use project-specific build/test targets.
- Prefer repository-owned `pre-commit` hooks and CI so checks work outside OpenCode.
- Optional `opencode-yaml-hooks` can execute shell actions without another LLM call; see `examples/hooks.yaml` and opt in per project.
- Keep full diagnostics in tool output/logs; send the agent a concise failure summary. Never silently count skipped checks as passed.
- Do not automatically rewrite files from hooks; avoid hook loops and concurrent mutations.


## Agent selection policy

- Explore/librarian: read and locate relevant files or documentation; avoid implementation.
- Prometheus/Oracle: design alternatives and risks for genuinely ambiguous or high-impact changes.
- Hephaestus/Sisyphus-junior: scoped implementation with tests.
- Momus/Oracle: independent review of high-risk or architectural changes.
- Avoid parallel agents writing the same files.

## Domain skill routing

| Task signals | Load skill |
| --- | --- |
| ROS 2, TF, QoS, launch, colcon | `ros2-engineering` |
| CAN, SPI, UART, frames, logic analyzer | `embedded-protocol-analysis` |
| C++, CMake, CLion, toolchains | `cpp-cmake-toolchains` |
| SLAM, MPC, INDI, optimization, numerical accuracy | `control-numerics` |
| Python, pytest, notebooks | `python-reproducibility` |
| Docker, Distrobox, cross-architecture builds | `container-dev-workflows` |

## Smoke tests (manual)

- `opencode --version` and `opencode models` must run.
- `opencode debug config` must parse without errors; inspect locally for secrets.
- Start OpenCode and confirm relevant skills are discoverable.
- Ask for a read-only plan on a sample project and confirm no files are changed.
- Ask for a small fix and verify tests and a minimal diff.
- Simulate fallback only with a disposable task; do not infer fallback from static configuration alone.
