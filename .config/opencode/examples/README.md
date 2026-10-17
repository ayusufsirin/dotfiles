# OpenCode optional tool hooks

The `opencode-yaml-hooks` plugin is installed by the main OpenCode config,
but no global hooks are enabled. This is deliberate: a global command cannot
assume a project's language, toolchain, or working directory.

To enable for a particular project:

```sh
mkdir -p .opencode/hook
cp ~/.config/opencode/examples/hooks.yaml .opencode/hook/hooks.yaml
```

Review the copied commands before running OpenCode. The sample runs Ruff on
the whole project **once at main-session idle**, not after every edit.
For a large repository, prefer a project-specific pre-commit config or
targeted script maintained by that project.

`clangd` provides IDE/LSP diagnostics. For C/C++, configure CMake to export
`compile_commands.json` in the build environment and run `clang-tidy`
explicitly on changed files at task completion, or via pre-commit/CI.

The plugin's `file.changed` event only tracks supported OpenCode mutation
tools; edits made by arbitrary shell commands may not trigger it. Hook
failures on nonblocking events do not prevent an agent from finishing.
Keep CI as the authoritative quality gate.
