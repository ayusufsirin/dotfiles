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

## Fully offline installation

Set `NVIM_OFFLINE=1` when the machine's existing Git configuration can clone
the required repositories and the machine can reach Nexus, but it cannot reach
the public internet. In this profile:

- Lazy uses canonical `https://github.com/<owner>/<repo>.git` URLs. Git applies
  the machine's existing routing and authentication configuration.
- Tree-sitter clones 21 parser repositories with an explicit `.git` suffix,
  checks out the revisions pinned by nvim-treesitter, and compiles 22 local
  parser `.so` files with the system C compiler. It does not use GitHub archive
  downloads.
- Mason uses pinned package versions, Nexus npm/PyPI endpoints, and HTTP release
  assets proxied by Nexus. Its public metadata providers are disabled.

Git and HTTP downloads are separate paths. No Git clone uses Nexus. This
repository does not define or change Git routing, authentication, or transport
settings. Nexus is used only for package registries and downloadable artifacts
such as GitHub Release files. Mason's pinned registry is one of those release
downloads, not a Git clone.

### Automated target-machine setup

The target profile is a data file, not a shell script. Create it on the offline
machine after cloning this repository:

```bash
mkdir -p ~/.config/nvim-offline
install -m 600 .config/nvim/offline.env.example ~/.config/nvim-offline/env
${EDITOR:-vi} ~/.config/nvim-offline/env
```

The minimum profile contains:

```text
NVIM_OFFLINE=1
NVIM_NEXUS_URL=http://nexus.company.example:8081
```

The Nexus release, Cortex-Debug, PyPI, and npm URLs are derived from the Nexus
base. The longer endpoint variables shown in the template remain available as
overrides. Exported process variables take precedence over profile values.

Confirm that a canonical suffixed URL already clones successfully with the
machine's Git configuration, then run:

```bash
git ls-remote --exit-code https://github.com/tree-sitter/tree-sitter-c.git HEAD
```

Then start the setup:

```bash
./scripts/setup-nvim-offline.sh
```

The command validates prerequisites without running sudo, generates the Git
repository manifest from the actual plugin specs, verifies every canonical URL
using the existing Git configuration, checks Nexus, safely creates the Neovim
config symlink, performs an isolated installation, and verifies every pinned
tool and parser. It stops rather than replacing an unrelated existing
`~/.config/nvim`.

Use `./scripts/setup-nvim-offline.sh --preflight-only` to verify Git and Nexus
without installing Neovim data. Normal `nvim` launches automatically read
`~/.config/nvim-offline/env`. A custom profile can be tested with `--profile
FILE`, but normal launches then also require `NVIM_OFFLINE_PROFILE=FILE`.

The setup requires Neovim 0.10+, Git, curl, tar, gzip, unzip, ripgrep, fd,
Python with venv support, Node/npm, and a C compiler. On Debian/Ubuntu the
corresponding packages are `neovim git curl tar gzip unzip ripgrep fd-find
python3 python3-venv nodejs npm build-essential`.

Git authentication and routing remain entirely outside this repository. The
setup does not read tokens, inspect authentication methods, or run `git config`.
It generates every Lazy and Tree-sitter clone URL with the `.git` suffix before
passing that canonical URL to Git.

`NVIM_NEXUS_GITHUB_URL` remains accepted as a compatibility alias for
`NVIM_GITHUB_RELEASE_BASE_URL`.

The Nexus HTTP proxy for GitHub Release downloads must contain these Linux
x86-64 assets. These are downloadable files, not Git clones:

- `mason-org/mason-registry`, release `2026-04-06-bumpy-enemy`:
  `registry.json.zip` and `checksums.txt`
- `clangd/clangd`, release `22.1.0`: `clangd-linux-22.1.0.zip`
- `vadimcn/vscode-lldb`, release `v1.12.1`: `codelldb-linux-x64.vsix`
- `LuaLS/lua-language-server`, release `3.18.0`:
  `lua-language-server-3.18.0-linux-x64.tar.gz`
- `artempyanykh/marksman`, release `2026-02-08`: `marksman-linux-x64`
- `vscode-shellcheck/shellcheck-binaries`, release `v0.11.0`:
  `shellcheck-v0.11.0.linux.x86_64.tar.gz`
- `mvdan/sh`, release `v3.13.0`: `shfmt_v3.13.0_linux_amd64`
- `johnnymorganz/stylua`, release `v2.4.0`: `stylua-linux-x86_64.zip`

The Cortex-Debug VSIX comes from the exact marketplace URL configured above.
The Nexus PyPI repository must contain `clang-format`, `debugpy`, `rstcheck`,
and `ruff` at the pinned versions in `lua/config/offline.lua`, including their
dependencies. The npm repository must contain `markdownlint-cli2`, `prettier`,
`pyright`, and `yaml-language-server`, including transitive dependencies.

Make these 21 parser repositories reachable through the machine's existing Git
configuration:

```text
tree-sitter/tree-sitter-bash
tree-sitter/tree-sitter-c
tree-sitter/tree-sitter-cpp
stsewd/tree-sitter-comment
tree-sitter/tree-sitter-css
camdencheek/tree-sitter-dockerfile
the-mikedavis/tree-sitter-git-config
gbprod/tree-sitter-gitcommit
shunsambongi/tree-sitter-gitignore
tree-sitter/tree-sitter-go
tree-sitter/tree-sitter-json
MunifTanjim/tree-sitter-lua
MDeiml/tree-sitter-markdown
tree-sitter/tree-sitter-python
nvim-treesitter/tree-sitter-query
stsewd/tree-sitter-rst
tree-sitter/tree-sitter-rust
tree-sitter-grammars/tree-sitter-toml
neovim/tree-sitter-vim
neovim/tree-sitter-vimdoc
tree-sitter-grammars/tree-sitter-yaml
```

`markdown` and `markdown_inline` share `MDeiml/tree-sitter-markdown`, giving 22
parsers from 21 repositories. The offline machine also needs a C compiler.

Before disconnecting Nexus from its upstreams, perform the automated preflight
and a clean end-to-end installation:

```bash
~/.dotfiles/scripts/setup-nvim-offline.sh --preflight-only
~/.dotfiles/scripts/setup-nvim-offline.sh
```

The prime phase uses isolated XDG directories, so success proves all required
content is reachable rather than reusing the current Neovim cache. It fails
unless every pinned Mason receipt and every compiled parser exists. Set
`NVIM_OFFLINE_KEEP_TMP=1` to retain the isolated installation for inspection,
or set `NVIM_OFFLINE_PRIME_ROOT` to choose a new empty directory. Inside
Neovim, `:NvimOfflineHealth` verifies the profile, prerequisites, pinned Mason
receipts, and all configured parsers.

### Clean Debian and Ubuntu Docker test

The repository includes one parameterized Dockerfile and a runner that performs
a zero-cache install on both Debian 12 and Ubuntu 22.04:

```bash
cp .env.example .env
# Edit .env for Nexus and the external Git-config file.
./scripts/test-nvim-offline-docker.sh
```

The runner automatically loads the repository-root `.env`; explicitly exported
variables take precedence. Set `NVIM_TEST_ENV_FILE` to use another file. The
local `.env` is ignored by Git, while `.env.example` is safe to commit. The
runner mounts the selected, self-contained Git config only for the installation
step as a BuildKit secret. The file is absent from the resulting image. Any Git
routing and authentication required by the build must already be present in
that external file.

Useful runner overrides are:

```text
NVIM_NEXUS_URL                 canonical Nexus base URL
NVIM_TEST_NEXUS_URL            alternate Nexus base URL
NVIM_TEST_GIT_CONFIG_FILE      self-contained Git config passed as a secret
NVIM_TEST_INTERNAL_CA_FILE     optional internal CA passed as a secret
NVIM_TEST_DOCKER_NETWORK       Docker build network (for example, host)
NVIM_TEST_PULL_BASES=0         use already-present base images
NVIM_TEST_DEBIAN_IMAGE         alternate Debian 12 base image reference
NVIM_TEST_UBUNTU_IMAGE         alternate Ubuntu 22.04 base image reference
NVIM_TEST_ENV_FILE             alternate shell-format environment file
```

For example, use the host's self-contained Git config and local network:

```bash
NVIM_TEST_GIT_CONFIG_FILE="$HOME/.gitconfig" \
NVIM_TEST_DOCKER_NETWORK=host \
NVIM_TEST_PULL_BASES=0 \
  ./scripts/test-nvim-offline-docker.sh
```

Neither `NVIM_TEST_NEXUS_URL` nor `NVIM_NEXUS_URL` participates in Git routing.
The base images themselves must already be local or available through the
Docker daemon's configured registry. Set the two image overrides when the
internal Docker registry exposes different image names. APT packages, Node,
Neovim, Mason artifacts, npm/PyPI packages, and Cortex-Debug use Nexus. Plugins
and Tree-sitter source use canonical GitHub URLs handled by the supplied Git
config.

The Dockerfile is at `tests/docker/nvim-offline/Dockerfile`. Its final verifier
expects Neovim 0.12.3, Node 22.23.2, 16 pinned Mason tools, and 22 parsers.

To build only Debian directly, use the same Nexus values as `.env` and pass the
external Git config as a BuildKit secret:

```bash
set -a
source .env
set +a
nexus_host="$(printf '%s' "$NVIM_NEXUS_URL" | sed -E 's#^https?://([^/:]+).*#\1#')"

docker build --file tests/docker/nvim-offline/Dockerfile \
  --pull=false \
  --network "$NVIM_TEST_DOCKER_NETWORK" \
  --build-arg BASE_IMAGE=debian:12 \
  --build-arg DISTRO=debian \
  --build-arg NEXUS_URL="$NVIM_NEXUS_URL" \
  --build-arg NEXUS_HOST="$nexus_host" \
  --secret id=git_config,src="$NVIM_TEST_GIT_CONFIG_FILE" \
  --tag nvim-offline-test:debian .
```

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

## `appdev.nvim` local plugin

ROS2 and STM32 workflows are routed through a local plugin namespace,
`appdev.nvim`. The plugin detects the active application type from the current
file, exposes command-first actions, and delegates heavy UI to `overseer.nvim`
and `nvim-dap`.

Primary commands:

- `:AppDevBuild` runs the active adapter's build action.
- `:AppDevRun` runs the active adapter's run action when available.
- `:AppDevDebug` launches the active adapter's default debug flow.
- `:AppDevInspect` opens adapter-specific environment/project details.
- `:AppDevAction` selects or runs an adapter action by id.
- `:AppDevTask` selects task-style actions only.
- `:AppDevRefresh` clears cached project detection.

Adapters are registered from `lua/appdev/adapters/`. STM32 has higher priority
than ROS2, so a directory with both marker sets shows STM32 actions. Project
actions in keymaps and the winbar are thin wrappers over these commands.

STM32CubeCLT can be configured globally through an environment variable or setup
options:

```bash
export STM32CUBECLT_DIR=/path/to/STM32CubeCLT
```

```lua
require("appdev").setup({
  adapters = {
    stm32 = {
      cubeclt = {
        install_dir = "/path/to/STM32CubeCLT",
        workspace_dir = vim.fn.stdpath("cache") .. "/appdev-stm32-workspace",
      },
    },
  },
})
```

When a CubeIDE project has `.cproject` Debug/Release configurations but no
generated `Debug/Makefile`, `:AppDevBuild` uses the CubeCLT headless managed
builder. If a generated Makefile exists, AppDev keeps using `make`.

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

- STM32CubeCLT — used for headless CubeIDE managed builds when generated Makefiles are absent.
- `make` — used to drive CubeIDE-generated Makefiles when they exist.
- STM32CubeProgrammer CLI (`STM32_Programmer_CLI`) — used for flash and erase tasks. It is normally installed as part of STM32CubeCLT or standalone STM32CubeProgrammer. Add it to your `PATH`.
- `arm-none-eabi-gdb` — used by `nvim-dap-cortex-debug` for DAP debugging. It is also part of STM32CubeCLT or a standalone GNU Arm Embedded Toolchain.

Optional but common:

- `openocd` — if you want the OpenOCD debug server path instead of, or alongside, ST-LINK_gdbserver.
- `compiledb` or `bear` — to generate `compile_commands.json` for `clangd`.
- udev rules for ST-LINK / CMSIS-DAP probes on Linux, so your user can access debug adapters without `sudo`.

If these tools are missing, Neovim still starts cleanly and the STM32 tasks simply show actionable messages explaining what to install.

### Available tasks

Inside an STM32CubeIDE project, open the Overseer task picker with `<leader>or` or run `:OverseerRun`. The following tasks appear:

- `STM32: build` — uses `make -C <default-config>` when generated Makefiles exist, otherwise uses the configured STM32CubeCLT headless managed builder.
- `STM32: clean` — uses `make clean` or CubeCLT clean-build for managed-only projects.
- `STM32: refresh managed build` — imports/refreshes the CubeIDE project in the configured CubeCLT workspace.
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

Some settings vary by board or probe and should live with the project, not in the dotfiles. Project-local Lua overrides are executable code and are only read because this config explicitly enables trusted project Lua in `lua/plugins/appdev.lua`. Create one of:

- `.nvim/appdev.lua`
- `.nvim/stm32.lua`
- `.stm32-nvim.lua`

The file must return a Lua table, either directly or under a `stm32` key:

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

- `nvim --headless -u NONE -l tests/appdev_smoke.lua` verifies adapter registration and no-hardware project detection.
- `nvim --headless '+lua require("appdev").setup({ project_config = { trusted_lua = false } })' +qa` loads the plugin cleanly.
- `nvim --headless '+lua require("lazy").load({ plugins = { "overseer.nvim" } })' '+lua require("overseer.template.appdev")' +qa` loads the task template bridge.
- `nvim --headless '+lua require("lazy").load({ plugins = { "nvim-dap" } })' +qa` loads DAP cleanly.
- Open a file inside a fake STM32 fixture (`.ioc`, `.project`, `Debug/Makefile`) and run `<leader>dsi` or `:AppDevInspect` to see detected project details without running any tools.

### Optional hardware QA

Real flashing, OpenOCD connections, and GDB debugging require a connected board and probe. The checks below are **optional, manual, and not run by baseline verification**. Do not run them automatically or put them in scripts that run by default.

Before running any hardware command, you must explicitly opt in **and** supply the project-specific context yourself:

1. Set the gate variable:
   ```bash
   export STM32_QA_HARDWARE=1
   ```
2. Provide your own OpenOCD target config (for example `target/stm32f4x.cfg`, `target/stm32h7x.cfg`, or the cfg matching your MCU), your own project path, and your own ELF path. The commands below use placeholders such as `<target>`, `<project-path>`, and `<elf>`; replace them with real values for your board and build.

Manual hardware smoke checklist (run only after the two steps above):

- Confirm the probe is visible:
  ```bash
  STM32_Programmer_CLI -l
  ```
- Confirm SWD connection (does not erase or flash; replace `<project-path>` with your project directory if you run it from a script):
  ```bash
  STM32_Programmer_CLI -c port=SWD
  ```
- Start OpenOCD and verify target detection (replace `<target>` with your MCU cfg, for example `stm32f4x`):
  ```bash
  openocd -f interface/stlink.cfg -f target/<target>.cfg -c "init; targets; shutdown"
  ```
- Connect GDB to the running OpenOCD server and inspect registers (replace `<elf>` with your built ELF path):
  ```bash
  arm-none-eabi-gdb <elf> -ex "target extended-remote :3333" -ex "monitor reset halt" -ex "info registers" -ex "detach" -ex "quit"
  ```

These commands are examples for you to copy, review, and run deliberately. Automated verification and CI scripts must skip them unless `STM32_QA_HARDWARE=1` is set and every placeholder has been replaced by an explicit, reviewed value.

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
