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

Recommended external tools:

- `git`
- `ripgrep`
- `fd` or `fdfind`
- `python3`
- `node`
- `clangd`
- `clang-format`
- `shellcheck`
- `shfmt`
- `tree` is not required; the sidebar is provided by Neovim plugins.
- `trouble` is provided by Neovim plugins for diagnostics, quickfix, and location lists.

The first launch bootstraps `lazy.nvim` and Mason-managed language tools.

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
