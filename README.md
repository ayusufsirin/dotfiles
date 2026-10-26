# dotfiles
My humble dot files :D

## tmux

From this repository's root, link the config:

```sh
ln -s "$PWD/.tmux.conf" ~/.tmux.conf
```

If tmux is already running, reload the config:

```sh
tmux source-file ~/.tmux.conf
```

Mouse scrolling is enabled with a 10,000-line history buffer.
