# dotfiles

Personal Linux configuration for editors, terminals, Git, and Logitech devices.
Each integration can be installed separately.

## Setup

The examples below run from the repository root:

```bash
git clone https://github.com/ayusufsirin/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Install the applications you want to use and move any existing destination
configuration aside before linking it. The `ln -sT` commands below create links
without replacing existing files or placing links inside existing directories.

## Neovim

Terminal development environment with completion, language servers, formatting,
diagnostics, Git actions, sessions, and project navigation. The local `appdev.nvim`
plugin adds ROS2 and STM32 build and debug workflows.

Use the [Neovim guide](.config/nvim/README.md) for:

- [Prerequisites](.config/nvim/README.md#machine-prerequisites) and
  [installation](.config/nvim/README.md#install).
- [Offline installation through existing Git access and Nexus](.config/nvim/README.md#fully-offline-installation).
- [ROS2 debugging](.config/nvim/README.md#ros2-debugging).
- [STM32CubeIDE integration](.config/nvim/README.md#stm32cubeide-workflow).
- [Verification](.config/nvim/README.md#first-run-verification) and
  [troubleshooting](.config/nvim/README.md#troubleshooting).

## Git aliases

[The alias configuration](.config/git/aliases.gitconfig) adds `git adgo` to show
the commit graph across all branches. Include it in your global Git configuration:

```bash
git config --global --add include.path "$PWD/.config/git/aliases.gitconfig"
git adgo
```

## Terminals

Both terminal configurations use the **JetBrainsMono Nerd Font Mono** font.

### Konsole

The [Gruvbox profile](.config/konsole/Gruvbox-Dotfiles.profile) uses the bundled
[color scheme](.config/konsole/Gruvbox-Dotfiles.colorscheme). Konsole stores user
profiles in `$XDG_DATA_HOME/konsole`, normally `~/.local/share/konsole`, as described
in the [KDE handbook](https://docs.kde.org/stable_kf6/en/konsole/konsole/profiles.html).

```bash
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/konsole"
ln -sT "$PWD/.config/konsole/Gruvbox-Dotfiles.profile" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/konsole/Gruvbox-Dotfiles.profile"
ln -sT "$PWD/.config/konsole/Gruvbox-Dotfiles.colorscheme" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/konsole/Gruvbox-Dotfiles.colorscheme"
```

Select **Gruvbox Dotfiles** in Konsole's profile settings.

### Terminator

[The Terminator configuration](.config/terminator/config) provides a Gruvbox
palette, a transparent background, and the default terminal layout.

```bash
mkdir -p ~/.config/terminator
ln -sT "$PWD/.config/terminator/config" ~/.config/terminator/config
```

## Solaar

[The Solaar rules](.config/solaar/rules.yaml) map M720 wheel tilts to desktop
navigation and synchronize the mouse host with the MX Mechanical Mini keyboard's
Easy-Switch selection. Adjust the device IDs and desktop shortcuts for your hardware.

```bash
mkdir -p ~/.config/solaar
ln -sT "$PWD/.config/solaar/rules.yaml" ~/.config/solaar/rules.yaml
```

## Vim

[The Vim configuration](.vimrc) uses Vundle for plugins, including Gruvbox,
NERDTree, Git integration, and language syntax support.

```bash
ln -sT "$PWD/.vimrc" ~/.vimrc
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

Open Vim and run `:PluginInstall` to install its plugins.
