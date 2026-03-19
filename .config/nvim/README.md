# Neovim config

Portable Neovim configuration for terminal development under `.dotfiles/.config/nvim`.

## Layout

The config is stored directly in the dotfiles repo and can be symlinked into `~/.config/nvim`:

```text
~/.dotfiles/.config/nvim
```

## Requirements

This configuration targets a modern Neovim build, ideally `0.10+`.

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
