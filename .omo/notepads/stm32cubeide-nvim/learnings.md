
## 2026-06-27T00:54:10.392633+03:00 - Task 3 project actions registry
- `config.project_actions` now owns inactive project winbar actions; ROS2 registers detect/actions/callbacks there while `debug_ui` keeps active DAP controls local.
- Keep ROS2 callback global names stable (`DebugRosBuild`, `DebugRosRun`, `DebugRosPython`, `DebugRosCpp`, `DebugRosAttach`) so existing winbar click semantics remain compatible.
- Non-project cwd should show only the shared DAP UI inactive button; fake ROS2 workspace detection can be tested with `src/` plus `build/`.

## 2026-06-27T01:06:53.447894+03:00 - Task 4 ROS2 regression fixture
- A self-contained `/tmp/nvim-ros2-regression-fixture` with `src/demo_pkg/package.xml`, `install/local_setup.bash`, and executable `install/demo_pkg/lib/demo_pkg/talker` is enough to validate ROS2 command/config generation without running `colcon` or requiring hardware.
- `workspace_build_command()` emits shell-escaped tokens; normalize quotes in evidence checks when asserting the documented `colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` sequence.
- Real-config headless Neovim is required for `cpp_configurations()` because it references `dap.utils`; `--clean` intentionally omits that plugin path and is not the compatibility baseline.


## 2026-06-27T01:09:44+03:00 - Task 6 STM32CubeIDE discovery
- `config.stm32_debug` is discovery-only: it walks upward via `config.dev_utils.find_upward` and recognizes `.ioc`, `.project`, `.cproject`, `.mxproject`, `Debug/Makefile`, and `Release/Makefile` without mutating CubeIDE files or running toolchains.
- Build config selection is deterministic and intentionally small: `Debug` wins when present, `Release` works alone, and ELF candidates are globbed under the selected config directory.
- Project names prefer the `.ioc` basename, then a simple `.project` `<name>`, then the directory basename; keep future tasks from adding brittle XML parsing unless necessary.
- Baseline QA uses headless Neovim fake fixtures only; no hardware, make, OpenOCD, STM32_Programmer_CLI, or GDB is required for discovery.

## 2026-06-27T03:51:00+03:00 - Task 7 STM32 overseer tasks
- Follow the existing `lua/overseer/template/ros2.lua` generator pattern: a module returns `{ name = "stm32", generator = function(opts) ... end }` and yields task tables via `config.task_utils.template`/`task`.
- `config.stm32_debug.current_project(opts.dir)` is sufficient for project detection; reuse its `default_config`, `root`, `project_name`, and `elf_candidates` instead of duplicating root-detection logic.
- Build/clean commands use `make -C <default_config>` / `make clean -C <default_config>` so they follow CubeIDE Makefile layout without hardcoding Debug/Release.
- Compile DB generation prefers `compiledb`, falls back to `bear`, and degrades to an actionable missing-tool echo task when neither is installed; this keeps task generation safe and non-crashing.
- Flash auto-selects the sole ELF candidate; when multiple exist it prompts with `vim.fn.inputlist`, and when none exist it prompts for a path. Erase requires typing "erase" before generating the `STM32_Programmer_CLI -e all` command.
- OpenOCD server defaults to `interface/stlink.cfg` and prompts for a target cfg (e.g. `target/stm32f4x.cfg`), making it easy to override per MCU/board later.
- Headless QA mocks `vim.fn.input` for erase/openocd/flash-multiple paths and temporarily prepends a fake `compiledb` to PATH to verify the tool-preference branch without running real tools.

## 2026-06-27T00:51:13+03:00 - Task 9 STM32 command builders and inspection
- Added `build_current_config`, `clean_current_config`, `generate_compile_commands`, `flash_elf`, `erase_chip`, `start_openocd`, and `inspect_environment` to `config.stm32_debug`.
- Command builders return shell command strings only; they do not execute `STM32_Programmer_CLI`, OpenOCD, GDB, or any hardware action, so headless fixture tests are safe.
- Missing-tool checks use `config.dev_utils.executable` and return actionable messages (e.g., install STM32CubeProgrammer / STM32CubeCLT, OpenOCD, arm-none-eabi-gdb, compiledb/bear).
- `inspect_environment` (and `inspect_environment_lines`) report project root, configs, ELF candidates, tool availability, OpenOCD interface/target choice, and suggested next steps.
- `erase_chip` requires `confirmed=true` to build the command; this prevents accidental automatic erase.
- `generate_compile_commands` prefers `compiledb`, falls back to `bear`, and reports a clear error if neither is available.
- `start_openocd` defaults to `interface/stlink.cfg` and requires an explicit target cfg override; it now also checks `openocd` availability.
- Build command uses a portable `$(nproc 2>/dev/null || echo 4)` jobs expression so it degrades safely on systems without `nproc`.
- Fake-fixture QA passes with all STM32 tools mocked and with all STM32 tools missing; no hardware or real toolchain execution occurred.

## 2026-06-27T08:42:00+03:00 - Task 8 nvim-dap-cortex-debug wiring
- Added `jedrzejboczar/nvim-dap-cortex-debug` as a dependency of `nvim-dap`; setup is guarded by `pcall` so missing STM32 tooling never crashes Neovim startup.
- `dap-cortex-debug.setup({ dapui_rtt = true, node_path = "node" })` is called after `dapui.setup` and before DAP event listeners, keeping existing codelldb/debugpy/ROS2 configs untouched.
- Mason `ensure_installed` now builds dynamically: `cortex-debug` is inserted only when `mason-registry.has_package("cortex-debug")` reports true, preventing installer errors if the registry entry is unavailable.
- Headless verification passes with the full PATH, with a constrained PATH, and with `checkhealth dap-cortex-debug`; no hardware or STM32 toolchain is required.

## 2026-06-27T08:49:23+03:00 - Task 10 STM32 Cortex-M DAP configurations
- `stm32_debug.cortex_configurations()` resolves DAP config only when the OpenOCD target is explicit (opts, project field, or `.nvim/stm32.lua`/`.stm32-nvim.lua` override) and the ELF is unambiguous (explicit path or exactly one candidate).
- The `executable` field is resolved to an absolute path before returning so the config is deterministic; `launch_debug()` prompts for target/ELF when needed and returns `dap.ABORT` instead of running an invalid config.
- `dap.configurations.c` and `.cpp` are extended after codelldb and ROS2 configs, so `Launch file` and ROS2 C++ configs remain intact.
- A sandboxed local override loader (`loadfile(path, "t", {})`) lets projects keep interface/target/SVD settings under `.nvim/stm32.lua` without executing arbitrary global code.
- Headless QA for `cortex_configurations` must capture the second return value as the project object, because the function returns `(configs, project)` on success and `(nil, err, project)` on failure.

## 2026-06-27T08:56:00+03:00 - Task 11 STM32 debug keymaps and winbar actions
- Added `<leader>ds*` keymaps for STM32 workflows: `dsb` build, `dsc` clean, `dsg` generate compile_commands.json, `dsf` flash, `dse` erase, `dso` OpenOCD server, `dsd` debug, `dsi` inspect.
- STM32 winbar actions are registered through the shared `config.project_actions` registry, reusing `config.stm32_debug` helpers and the existing overseer templates from Task 7; no hardware commands run on winbar display.
- New global click callbacks follow the `DebugStm32*` naming convention (`DebugStm32Build`, `DebugStm32Clean`, `DebugStm32CompileDb`, `DebugStm32Flash`, `DebugStm32Erase`, `DebugStm32OpenOCD`, `DebugStm32Debug`, `DebugStm32Inspect`) and do not collide with ROS2 `DebugRos*` callbacks or generic DAP mappings.
- Provider priority makes overlap deterministic: STM32 priority 10, ROS2 priority 100, so STM32 wins when a directory contains both STM32 and ROS2 markers. This is intentional because an embedded firmware project is more specific than a generic ROS2 workspace.
- Headless winbar QA must open a buffer inside the fixture; `current_project()` uses the current buffer path via `config.dev_utils.start_path`, not the global cwd, so an empty headless buffer would otherwise fail detection.
- ROS2 `<leader>dr*` mappings, generic `<leader>d[bcioOu]` mappings, and winbar labels remain intact; the new `<leader>ds*` prefix avoids all existing DAP/ROS2 collisions.

## 2026-06-27T09:00:00+03:00 - Task 12 documentation
- README.md now contains one consolidated STM32CubeIDE workflow section that covers prerequisites, task names (`STM32: build`, `STM32: clean`, `STM32: generate compile_commands.json`, `STM32: flash`, `STM32: erase`, `STM32: openocd server`), keymaps (`<leader>dsb/dsc/dsg/dsf/dse/dso/dsd/dsi`), project-local overrides (`.nvim/stm32.lua`, `.stm32-nvim.lua`), `.clangd`/compile_commands guidance, no-hardware verification, and opt-in hardware QA.
- Documentation explicitly states that CubeMX/CubeIDE owns `.ioc`/Makefile generation and that the Neovim workflow does not auto-flash, auto-erase, auto-connect, or mutate CubeIDE metadata.
- PROMPTS.md adds a future-maintenance prompt (#10) for STM32/embedded workflow evolution with the same guardrails.
- Verification grep targets: `STM32`, `CubeIDE`, `STM32_Programmer_CLI`, `OpenOCD`, `compile_commands` in README.md; `STM32`/`embedded` in PROMPTS.md; no `auto-flash` or `automatically flash` misleading claims in README.md.


## 2026-06-27T09:17:08+03:00 - Task 14 gated hardware QA
- README.md "Optional hardware QA" section is now explicitly gated: it requires `export STM32_QA_HARDWARE=1` plus user-supplied OpenOCD target, project path, and ELF path before any hardware command is considered.
- Checklist remains optional and manual; it is not executed by baseline verification or automated scripts.
- Included example commands: `STM32_Programmer_CLI -l`, `STM32_Programmer_CLI -c port=SWD`, `openocd -f interface/stlink.cfg -f target/<target>.cfg -c "init; targets; shutdown"`, and `arm-none-eabi-gdb <elf> -ex "target extended-remote :3333" -ex "monitor reset halt" -ex "info registers" -ex "detach" -ex "quit"`.
- Task 13 evidence inspection confirms no `STM32_QA_HARDWARE=1` was set and no actual `STM32_Programmer_CLI -c port=SWD`, `openocd -f`, or `arm-none-eabi-gdb ... target extended-remote` execution occurred by default.
- No hardware commands were run during Task 14; only README edits, grep verification, and evidence logging were performed.
