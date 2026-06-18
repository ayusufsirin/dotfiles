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
