# Neovim config

Portable Neovim configuration for terminal development under `.dotfiles/.config/nvim`.

## Layout

The config lives directly in the dotfiles repo:

```text
~/.dotfiles/.config/nvim
```

## What this setup expects

This configuration targets modern Neovim, preferably `0.10+`.
It is built around:

- `lazy.nvim` for plugin management
- `mason.nvim` and `mason-tool-installer.nvim` for editor-side language tools
- terminal-first workflows with mouse support, split navigation, a persistent tree, sessions, diagnostics sidebars, and git gutter actions

## Machine prerequisites

These must exist on the machine before the config can bootstrap cleanly:

- `nvim`
- `git`
- `curl`
- `tar`
- `gzip`
- `unzip`
- `ripgrep`
- `fd` or `fdfind`
- `python3`
- `python3-venv`
- `node`
- `npm`

Useful extras:

- `xclip` or `wl-clipboard` on Linux for `clipboard=unnamedplus`
- `make` and a C toolchain if you later add plugins with native builds

### Debian / Ubuntu

```bash
sudo apt update
sudo apt install -y neovim git curl tar gzip unzip ripgrep fd-find python3 python3-venv nodejs npm xclip
```

### Fedora

```bash
sudo dnf install -y neovim git curl tar gzip unzip ripgrep fd-find python3 python3-pip python3-virtualenv nodejs npm xclip
```

### Arch

```bash
sudo pacman -S --needed neovim git curl tar gzip unzip ripgrep fd python python-virtualenv nodejs npm xclip
```

### macOS

```bash
brew install neovim git curl ripgrep fd python node
```

## What Mason installs for you

On first launch, Mason is configured to install these tools automatically:

- `clangd`
- `clang-format`
- `codelldb`
- `debugpy`
- `lua-language-server`
- `markdownlint-cli2`
- `marksman`
- `prettier`
- `pyright`
- `rstcheck`
- `ruff`
- `shellcheck`
- `shfmt`
- `stylua`
- `yaml-language-server`

That means you do not need to install those manually in the normal case.
The main requirement is that Python virtual environments and npm-backed installs work on the machine.

## Install

Clone the dotfiles repo wherever you keep it, then link this config:

```bash
mkdir -p ~/.config
ln -sfn ~/.dotfiles/.config/nvim ~/.config/nvim
```

Open Neovim once:

```bash
nvim
```

On the first run, let it finish:

- plugin bootstrap via `lazy.nvim`
- Mason registry setup
- automatic Mason tool installation

## First-run verification

Inside Neovim, these commands are the quickest sanity check:

```vim
:Lazy
:Mason
:checkhealth
```

For a full refresh later:

```vim
:Lazy sync
:MasonToolsInstall
:checkhealth
```

## Troubleshooting

If a tool is declared but missing, first try:

```vim
:Lazy sync
:MasonUpdate
:MasonToolsInstall
```

If a specific Mason install fails, inspect:

```vim
:MasonLog
```

Common causes:

- missing `python3-venv`
- missing `npm`
- interrupted first boot
- old system `nvim`

## ROS2 debugging

The config includes DAP support for Python and C++ ROS2 packages without requiring a
Neovim distribution. Build and run actions use `overseer.nvim` for task UI,
history, output, and task actions. ROS2 helpers detect a `colcon` workspace from
the current file or working directory, source the workspace setup file, and launch
installed nodes with the sourced ROS2 environment. If Neovim was started from an
unsourced shell, it will also source a single detected `/opt/ros/<distro>/setup.bash`
underlay before the workspace overlay.

Build workspaces with debug-friendly output before debugging. The Build button uses
the same flags and adds `--packages-up-to <current-package>` when the current file
is inside a ROS2 package:

```bash
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

Use these mappings from a ROS2 workspace:

- `<leader>drb` builds the current package and dependencies with `--packages-up-to`.
- `<leader>drr` picks and runs an installed ROS2 node in a terminal.
- `<leader>drp` picks and debugs an installed Python node.
- `<leader>drc` picks and debugs an installed C++ node with `codelldb`.
- `<leader>dra` attaches `codelldb` to an already-running ROS2 process.
- `<leader>dre` opens a scratch buffer with detected workspace and environment details.
- `<leader>du` toggles variables, watches, stack frames, breakpoints, REPL, and console views.
- `<leader>oo` toggles the Overseer task list.
- `<leader>or` opens Overseer's task picker.
- `<leader>oa` opens task actions for a selected task.

The file winbar also exposes clickable IDE-style controls. When no debug session is
active it shows Build, Run, Debug Python, Debug C++, attach, and UI buttons. During
a session it switches to continue, step, REPL, restart, stop, and UI buttons.

The left DAP sign column is clickable:

- left-click toggles a breakpoint on that line
- right-click creates a conditional breakpoint
- middle-click creates a log point

Prefer direct installed executable debugging for individual nodes. For nodes
started through `ros2 launch`, start the launch normally and use attach mode for
the target C++ process. Generic attach is not available for Python processes
unless they were started with a debugpy listener.

## STM32CubeIDE workflow

This config treats STM32CubeMX / STM32CubeIDE as the project generators and Neovim as the editor/terminal-IDE layer on top of them. The workflow is explicit: it never mutates `.ioc`, `.project`, `.cproject`, `.mxproject`, generated Makefiles, or linker scripts, and it never flashes, erases, or connects to hardware automatically. All hardware actions are started deliberately through a keymap, Overseer task, or `nvim-dap` launch.

Project detection walks upward from the current file or working directory and recognizes any of: `.ioc`, `.project`, `.cproject`, `.mxproject`, `Debug/Makefile`, `Release/Makefile`. When both `Debug` and `Release` Makefiles exist, `Debug` is selected by default.

### Prerequisites

Required on the host:

- `make` — used to drive the CubeIDE-generated Makefile.
- STM32CubeProgrammer CLI (`STM32_Programmer_CLI`) — used for flash and erase tasks. It is normally installed as part of STM32CubeCLT or standalone STM32CubeProgrammer. Add it to your `PATH`.
- `arm-none-eabi-gdb` — used by `nvim-dap-cortex-debug` for DAP debugging. It is also part of STM32CubeCLT or a standalone GNU Arm Embedded Toolchain.

Optional but common:

- `openocd` — if you want the OpenOCD debug server path instead of, or alongside, ST-LINK_gdbserver.
- `compiledb` or `bear` — to generate `compile_commands.json` for `clangd`.
- udev rules for ST-LINK / CMSIS-DAP probes on Linux, so your user can access debug adapters without `sudo`.

If these tools are missing, Neovim still starts cleanly and the STM32 tasks simply show actionable messages explaining what to install.

### Available tasks

Inside an STM32CubeIDE project, open the Overseer task picker with `<leader>or` or run `:OverseerRun`. The following tasks appear:

- `STM32: build` — `make -C <default-config>` (default config is `Debug` when present).
- `STM32: clean` — `make clean -C <default-config>`.
- `STM32: generate compile_commands.json` — prefers `compiledb`, falls back to `bear`; produces an actionable message if neither is installed.
- `STM32: flash` — prompts for or auto-selects an ELF, then builds the `STM32_Programmer_CLI` command. It does **not** run until you start the task.
- `STM32: erase` — requires typing `erase` to confirm before building the chip-erase command.
- `STM32: openocd server` — starts `openocd -f interface/stlink.cfg -f <target-cfg>`; prompts for the target config when none is set.

### Keymaps

Use these from an STM32 project buffer:

- `<leader>dsb` — build the selected config.
- `<leader>dsc` — clean the selected config.
- `<leader>dsg` — generate `compile_commands.json`.
- `<leader>dsf` — flash the selected ELF (prompts when ambiguous).
- `<leader>dse` — erase chip (requires confirmation).
- `<leader>dso` — start OpenOCD server.
- `<leader>dsd` — launch DAP debug through `nvim-dap-cortex-debug`.
- `<leader>dsi` — open a scratch buffer with project detection, tool availability, and suggested next steps.

Generic DAP controls remain unchanged: `<leader>db` toggle breakpoint, `<leader>dc` continue, `<leader>do` step over, `<leader>di` step into, `<leader>dO` step out, `<leader>du` toggle DAP UI.

### Winbar actions

When no debug session is active, the file winbar shows project-appropriate buttons. In an STM32 project you get Build, Flash, Debug, OpenOCD, Inspect, and UI toggles. STM32 detection has higher priority than ROS2 detection, so a directory that contains both STM32 and ROS2 markers shows STM32 buttons.

### Project-local overrides

Some settings vary by board or probe and should live with the project, not in the dotfiles. Create one of:

- `.nvim/stm32.lua`
- `.stm32-nvim.lua`

The file must return a Lua table, for example:

```lua
return {
  openocd_interface = "interface/stlink.cfg",
  openocd_target = "target/stm32f4x.cfg",
  svd_file = "STM32F407.svd",
}
```

Supported keys are `openocd_interface`, `openocd_target`, and `svd_file`. These override defaults and prompt values for the OpenOCD server and DAP debug configurations. Do not hardcode probe serial numbers, versioned install paths, or machine-specific absolute paths in files that are committed to shared repositories.

### `compile_commands.json` and `.clangd`

`clangd` works out of the box for host C/C++. For STM32 cross-compilation it needs a compilation database and a project-local `.clangd` file that points to the ARM toolchain driver. Do not hand-write `compile_commands.json`; generate it from the build system. STM32CubeMX / STM32CubeIDE remain responsible for `.ioc` generation and for producing the underlying Makefile or CMake project structure.

**Makefile-based project (most CubeMX/CubeIDE exports):**

```bash
# Bear wraps your build and captures every compiler invocation
bear -- make -j$(nproc)

# compiledb is an alternative if Bear is not available
compiledb make
```

**CMake-based project:**

Add to `CMakeLists.txt` or pass on the command line:

```cmake
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

Place or symlink the resulting `compile_commands.json` in your project root so clangd finds it automatically.

In the root of your STM32 project, create `.clangd`:

```yaml
CompileFlags:
  # Tell clangd which compiler driver to use when querying system headers.
  # Replace /path/to/toolchain with the actual location of your ARM toolchain
  # (e.g. STM32CubeCLT or a standalone GNU Arm Embedded Toolchain install).
  QueryDriver:
    - "/path/to/toolchain/bin/arm-none-eabi-*"

# If compile_commands.json lives in a subdirectory (e.g. build/), uncomment:
# CompilationDatabase: "build"
```

This approach keeps machine-specific toolchain paths out of the shared dotfiles and scopes them to the projects that actually need them. The global `lsp.lua` flags (`--background-index`, `--clang-tidy`, `--completion-style=detailed`, `--header-insertion=never`) continue to apply without modification.

### No-hardware verification

Baseline verification requires no board, no ST-LINK, and no STM32 toolchain:

- `nvim --headless '+lua require("config.stm32_debug")' +qa` loads the module cleanly.
- `nvim --headless '+lua require("lazy").load({ plugins = { "overseer.nvim" } })' '+lua require("overseer.template").load("stm32")' +qa` loads the task templates.
- `nvim --headless '+lua require("lazy").load({ plugins = { "nvim-dap" } })' +qa` loads DAP cleanly.
- Open a file inside a fake STM32 fixture (`.ioc`, `.project`, `Debug/Makefile`) and run `<leader>dsi` or `:lua require("config.stm32_debug").inspect_environment()` to see detected project details without running any tools.

### Optional hardware QA

Real flashing, OpenOCD connections, and GDB debugging require a connected board and probe. These checks are opt-in and are not executed automatically. A reasonable manual checklist, when you choose to run it, is:

- Confirm the probe is visible: `STM32_Programmer_CLI -l`
- Confirm SWD connection: `STM32_Programmer_CLI -c port=SWD`
- Start OpenOCD and verify target detection: `openocd -f interface/stlink.cfg -f target/<target>.cfg -c "init; targets; shutdown"`
- Connect GDB: `arm-none-eabi-gdb <elf> -ex "target extended-remote :3333" -ex "monitor reset halt" -ex "info registers" -ex "detach" -ex "quit"`

Keep these commands out of automated scripts unless you explicitly set a gate such as `STM32_QA_HARDWARE=1` and review every command before it runs.

## Notes

- Python uses `pyright`, formatting and linting via `ruff`, and debug support via `debugpy`.
- C and C++ use `clangd`, `clang-format`, and a `codelldb` debugging baseline.
- Markdown and reStructuredText get wrap/spell/textwidth-friendly filetype settings, and reStructuredText can be linted with `rstcheck`.
- YAML uses `yamlls` plus schema support from `schemastore.nvim`, with formatting through `prettier`.
- Mouse support is enabled for clicking, scrolling, split resizing, and window selection.
- `NvimTree` provides the persistent left sidebar, with `<leader>e` to toggle it and `<leader>E` to reveal the current file.
- `Telescope projects` and `<leader>pp` switch between projects.
- `persistence.nvim` provides session restore and save commands with `<leader>ps`, `<leader>pl`, and `<leader>ss`.
- `Trouble` powers diagnostics, quickfix, and location-list sidebars with `<leader>xx`, `<leader>xq`, and `<leader>xl`.
- Window movement and split creation use `<C-h/j/k/l>`, `<leader>sv`, `<leader>sh`, `<leader>se`, and `<leader>sc`.
- On startup with no file arguments, Neovim restores the current project session when one exists and opens the tree sidebar focused on the workspace.
- If you launch Neovim with explicit file arguments, it skips automatic session restore and starts with those files only.
- `Gitsigns` now highlights changed lines and changed line numbers. In the line-number gutter, single left-click opens a compact action menu, double left-click previews the hunk, right-click blames the line, and middle-click or Ctrl-left-click toggles inline blame. The keyboard fallback is `<leader>gm`.
