# Codex prompts

Use these prompts in future Codex sessions to keep evolving this Neovim setup without losing the current design.

## 1. Audit and tighten

```text
Review my Neovim config in /home/joseph/.dotfiles/.config/nvim as a terminal IDE setup. Focus on bugs, startup failures, missing dependencies, poor defaults, and portability problems. Fix issues directly, keep the config Lua-based and git-friendly, and verify with headless Neovim commands when possible. Do not redesign everything from scratch.
```

## 2. Python and reStructuredText

```text
Extend /home/joseph/.dotfiles/.config/nvim for serious Python and reStructuredText work. Keep the existing structure. Improve Python refactoring, testing, virtualenv discovery, debug workflows, docstring/snippet support, and RST authoring ergonomics. Add only plugins and tools that materially improve editing quality, explain external dependencies, and verify the config still starts cleanly.
```

## 3. C and C++

```text
Upgrade /home/joseph/.dotfiles/.config/nvim for C and C++ development in the terminal. Keep clangd and DAP working, improve compile_commands.json handling, add useful build/test shortcuts for CMake and Make projects, and make debugging smoother without turning the config into a GUI IDE clone. Verify keymaps and startup.
```

## 4. Writing workflow

```text
Improve Markdown, YAML, and reStructuredText editing in /home/joseph/.dotfiles/.config/nvim. Optimize for technical writing in the terminal: preview-friendly formatting, spell/wrap defaults, linting, link navigation, and table/list ergonomics. Keep the setup portable and avoid heavyweight plugins unless they clearly pay for themselves.
```

## 5. Minimalism pass

```text
Reduce complexity in /home/joseph/.dotfiles/.config/nvim without losing the current IDE features I use for Python, Markdown, RST, YAML, C, and C++. Remove plugins or settings that do not materially help, simplify keymaps, and keep the result maintainable for long-term dotfiles usage.
```

## 6. Mouse and tree sidebar

```text
Update /home/joseph/.dotfiles/.config/nvim to feel more like a mouse-friendly terminal IDE. Enable sensible mouse behavior for clicking, scrolling, split resizing, and window selection. Replace the current file explorer with a persistent NERDTree-like sidebar, preferably nvim-tree.lua, and wire up clear keymaps for toggling the tree, focusing it, and revealing the current file. Keep the config portable and verify with headless Neovim if possible.
```

## 7. Project navigation

```text
Extend /home/joseph/.dotfiles/.config/nvim for better project navigation in a mouse-friendly terminal IDE. Keep the current tree sidebar and mouse support, then add practical project switching, session restore, split/window movement, and diagnostics/quickfix/location-list workflows. Prefer lightweight plugins that materially improve navigation, keep the Lua/lazy.nvim structure, update docs and prompt notes, and verify with headless Neovim.
```

## 8. Startup behavior

```text
Refine the Neovim startup behavior in /home/joseph/.dotfiles/.config/nvim so it feels like a project IDE. When Neovim starts without explicit file arguments, restore the project session if one exists and open the tree sidebar focused on the workspace. When Neovim is launched with explicit file arguments, do not auto-restore a session. Keep this behavior conservative, portable, and easy to reason about.
```

## 9. Git gutter

```text
Extend /home/joseph/.dotfiles/.config/nvim with a stronger Git gutter experience. Keep using gitsigns.nvim, but improve changed-line visibility in the number/sign columns and add a popup-style line inspection menu triggered from the gutter if practical. Prefer maintained community plugins such as statuscol.nvim and dressing.nvim before inventing custom UI, and provide a keyboard fallback for the same actions. Verify the config still starts cleanly.
```
