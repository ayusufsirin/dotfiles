# learnings.md


## 2026-06-26T23:33:07+03:00 - Task 1 dev_utils extraction
- Extracted ROS2 path/fs/shell helpers into `lua/config/dev_utils.lua` while keeping ROS2-specific workspace/package logic in `lua/config/ros2_debug.lua`.
- `vim.fs.joinpath` preserves a leading empty segment differently than the old fallback; filtering nil/empty parts before both branches keeps `join("", "a") == "a"` and avoids a misleading Neovim exit-0 Lua assertion case.
- LSP diagnostics transport was unavailable in this run, so evidence relies on headless Neovim module load/assertion checks plus duplicate-helper grep.

## 2026-06-27T00:41:20+03:00 - Task 2 ROS2 task_utils extraction
- Extracted concrete Overseer helpers into `lua/config/task_utils.lua` and migrated ROS2 templates without changing names, descriptions, commands, cwd, or component sets.
- Installed `overseer.nvim` exposes `template.list/get_by_name` rather than `template.load`; the literal `template.load` probe exits 7, so fixture generation evidence uses the supported `template.list` path.
- ROS2 run task builders prompt for optional args; headless QA should wrap `ros2.run_command(item, {})` to bypass only the prompt while preserving command construction semantics.

## 2026-06-27T08:48:26+03:00 - Task 10 STM32 Cortex-M DAP configurations
- `stm32_debug.cortex_configurations()` resolves DAP config only when the OpenOCD target is explicit (opts, project field, or `.nvim/stm32.lua`/`.stm32-nvim.lua` override) and the ELF is unambiguous (explicit path or exactly one candidate).
- The `executable` field is resolved to an absolute path before returning so the config is deterministic; `launch_debug()` prompts for target/ELF when needed and returns `dap.ABORT` instead of running an invalid config.
- `dap.configurations.c` and `.cpp` are extended after codelldb and ROS2 configs, so `Launch file` and ROS2 C++ configs remain intact.
- A sandboxed local override loader (`loadfile(path, "t", {})`) lets projects keep interface/target/SVD settings under `.nvim/stm32.lua` without executing arbitrary global code.
- Headless QA for `cortex_configurations` must capture the second return value as the project object, because the function returns `(configs, project)` on success and `(nil, err, project)` on failure.

## 2026-06-27T06:11:58Z - Task 13 full no-hardware verification
- Ran baseline module loads (dev_utils, ros2_debug, stm32_debug): all exit 0.
- Ran Overseer ros2+stm32 template loads: exit 0 using supported template.list API with callback.
- Ran nvim-dap load and dap-cortex-debug checkhealth: completed without hardware execution.
- ROS2 fake fixture verified workspace/package/build command/config counts.
- STM32 fake fixture verified project detection, configs, ELF candidates, build/clean/flash/erase/openocd command builders, cortex DAP config fields.
- STM32 no-ELF fixture verified actionable missing-ELF/errors without execution.
- Missing-tool sanity confirmed tool status reporting is consistent.
- Transcript checked: no STM32_Programmer_CLI -c port=SWD, openocd -f, or arm-none-eabi-gdb target extended-remote executed by default.
- Evidence log: /home/joseph/.dotfiles/.config/nvim/.omo/evidence/task-13-stm32cubeide-nvim.log
- Fixtures cleaned up after capture.
