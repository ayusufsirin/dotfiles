
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
