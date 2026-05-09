# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for an Arch Linux + Hyprland (Wayland) setup, managed with GNU Stow. Running `stow --target="$HOME" .` from the repo root symlinks all tracked files into `$HOME`, mirroring the directory structure here.

## Install / Deploy

```bash
# Full fresh install (installs pacman/AUR packages + stows)
sh install.sh

# Re-stow after adding/changing files
stow --target="$HOME" .

# Remove symlinks
stow --delete --target="$HOME" .
```

Files and directories listed in `.stow-local-ignore` are excluded from stowing (`.git`, `README.*`, `install.sh`, `packages/`).

## Adding Dotfiles

Place config files at the same relative path as they appear under `$HOME`. For example, a file that should live at `~/.config/foo/bar.conf` goes at `.config/foo/bar.conf` in this repo. Then re-run `stow --target="$HOME" .`.

## Key Configuration Locations

| Tool | Path |
|---|---|
| Hyprland (WM) | `.config/hypr/hyprland.conf` |
| Waybar (status bar) | `.config/waybar/config`, `style.css` |
| Dunst (notifications) | `.config/dunst/dunstrc` |
| Kitty (terminal) | `.config/kitty/` |
| Tmux | `.config/tmux/tmux.conf` |
| Neovim (LazyVim) | `.config/nvim/` |
| Zsh | `.zshrc` |
| Sesh (session mgr) | `.config/sesh/sesh.toml` |
| Yazi (file manager) | `.config/yazi/` |
| Rofi (launcher) | `.config/rofi/` |

## Architecture Notes

**Shell**: Zsh with [antidote](https://github.com/mattmc3/antidote) for plugin management, starship prompt, fzf, and zoxide. Plugins are declared in `~/.zsh_plugins.txt` (not in this repo). Secrets are loaded on demand via `load_secrets` (autoloaded from `.zsh_autoload_functions/`), which unlocks Bitwarden CLI and exports API keys.

**Neovim**: LazyVim distribution with custom plugins in `.config/nvim/lua/plugins/`. Active LSPs: pyright + ruff (Python), tinymist (Typst), marksman (Markdown/Obsidian). Conform handles formatting, mason manages LSP/linter binaries.

**Tmux**: Prefix is `C-Space`. Sessions managed with sesh (fuzzy picker via `t`). TPM plugins include catppuccin theme, resurrect/continuum for session persistence, and vim-tmux-navigator.

**Hyprland**: Two monitors — `eDP-1` (laptop) and `HDMI-A-1` (external). `SUPER+O` runs `scripts/external_only.sh` to disable laptop display; `SUPER+P` restores default layout. Autostart: waybar, dunst, hyprpaper, wlsunset, hypridle.

**Packages**: `packages/pacman.txt` and `packages/aur.txt` list all managed packages. Edit these before running `install.sh` to add/remove software.

## Monitor Scripts

```bash
~/scripts/external_only.sh    # Disable laptop screen, use HDMI only
~/scripts/restore_default.sh  # Restore both monitors
```
