# Neovim config

Portable Neovim configuration for terminal development under `.dotfiles/.config/nvim`.

## Layout

The config is stored directly in the dotfiles repo and can be symlinked into `~/.config/nvim`:

```text
~/.dotfiles/.config/nvim
```

## Requirements

This configuration targets a modern Neovim build, ideally `0.10+`.
It is configured for mouse-driven editing in the terminal and uses a tree-style file sidebar instead of a floating explorer.
It also adds project switching, session restore, and diagnostics/quickfix sidebars for IDE-like navigation.

The first launch bootstraps `lazy.nvim` and Mason-managed language tools.
Some plugins and Mason packages still need system tools to be available before the first full setup.

### Ubuntu/Debian system packages

Install the baseline tools before opening Neovim for the first time:

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  curl \
  fd-find \
  git \
  nodejs \
  npm \
  python3 \
  python3-pip \
  python3.12-venv \
  ripgrep \
  unzip \
  xclip
```

On Ubuntu, the `fd-find` package installs the binary as `fdfind`.
Create an `fd` compatibility symlink for tools that expect the shorter command name:

```bash
mkdir -p ~/.local/bin
ln -sf /usr/bin/fdfind ~/.local/bin/fd
```

Make sure `~/.local/bin` is available in your shell PATH:

```bash
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

export PATH="$HOME/.local/bin:$PATH"
```

### Why these packages are needed

- `build-essential` provides `cc`/`gcc`, required for compiling Treesitter parsers.
- `ripgrep` powers Telescope live grep through the `rg` command.
- `fd-find` improves Telescope file discovery; the config expects an `fd` command.
- `nodejs` and `npm` are required by npm-based Mason packages such as `yaml-language-server` and `prettier`.
- `python3.12-venv` is required for Mason Python tools that create virtual environments, such as `ruff`.
- `python3`, `python3-pip`, `curl`, and `unzip` are common Mason/package installation helpers.
- `xclip` provides clipboard integration for `clipboard = "unnamedplus"` on X11 sessions.
- `git` is required by Lazy, Mason, Gitsigns, project detection, and normal plugin updates.

Optional tools:

- `tree-sitter` and `node` are only needed for `:TSInstallFromGrammar`; normal `:TSInstall` and `:TSUpdate` work without the `tree-sitter` CLI.
- Perl and Ruby providers are disabled in this config because they are not used by the current plugin set.
- Node provider warnings are only important if you want Node-based Neovim provider support or JavaScript/TypeScript development tooling.

## Install

```bash
mkdir -p ~/.config
ln -sfn /home/joseph/.dotfiles/.config/nvim ~/.config/nvim
```

Open Neovim once and let it install plugins and tools:

```bash
nvim
```

If you want to refresh plugin and tool installs later, run inside Neovim:

```vim
:Lazy sync
:Mason
```

For headless Mason installs, load the LSP plugin first so Mason commands are registered:

```bash
nvim --headless '+Lazy load nvim-lspconfig' '+MasonInstall ruff yaml-language-server' +qa
```

### Verify the setup

After the first install, these commands should print `1`:

```bash
nvim --headless '+lua print(vim.fn.executable("lua-language-server"))' +qa
nvim --headless '+lua print(vim.fn.executable("ruff"))' +qa
nvim --headless '+lua print(vim.fn.executable("yaml-language-server"))' +qa
```

Run health checks:

```bash
nvim --headless '+checkhealth' +qa
```

The important sections should be green for Lazy, Telescope, Treesitter, and `vim.lsp`.
Some informational warnings from plugin internals or optional providers can still appear.

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
- `Gitsigns` now highlights changed lines and changed line numbers, and clicking the line-number gutter opens a popup menu for hunk preview, blame, or inline blame toggling. The keyboard fallback is `<leader>gm`.
