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

| Tool                  | Path                                       |
| --------------------- | ------------------------------------------ |
| Hyprland (WM)         | `.config/hypr/hyprland.lua` (Lua config)   |
| Waybar (status bar)   | `.config/waybar/config`, `style.css`       |
| Dunst (notifications) | `.config/dunst/dunstrc`                    |
| Kitty (terminal)      | `.config/kitty/`                           |
| Ghostty (terminal)    | `.config/ghostty/config.ghostty`           |
| Tmux                  | `.config/tmux/tmux.conf`                   |
| Neovim (LazyVim)      | `.config/nvim/`                            |
| Zsh                   | `.zshrc`                                    |
| Sesh (session mgr)    | `.config/sesh/sesh.toml`                   |
| Yazi (file manager)   | `.config/yazi/`                            |
| Rofi (launcher)       | `.config/rofi/`                            |
| Darkman (light/dark)  | `.config/darkman/`, `.local/share/darkman/`|

## Architecture Notes

**Shell**: Zsh with [antidote](https://github.com/mattmc3/antidote) for plugin management, starship prompt, fzf, and zoxide. Plugins are declared in `~/.zsh_plugins.txt` (not in this repo). Secrets are loaded on demand via `load_secrets` (autoloaded from `.zsh_autoload_functions/`), which unlocks Bitwarden CLI and exports API keys.

**Neovim**: LazyVim distribution with custom plugins in `.config/nvim/lua/plugins/`. Active LSPs: pyright + ruff (Python), tinymist (Typst), marksman (Markdown/Obsidian). Conform handles formatting, mason manages LSP/linter binaries.

**Tmux**: Prefix is `C-Space`. Sessions managed with sesh (fuzzy picker via `t`). TPM plugins include catppuccin theme, resurrect/continuum for session persistence, and vim-tmux-navigator.

**Hyprland**: Configured in **Lua** (`hyprland.lua`), not hyprctl syntax — monitors, binds, and autostart are declared through an `hl.*` API (`hl.monitor`, `hl.bind`, `hl.on("hyprland.start", ...)` + `hl.exec_cmd`). `monitors.conf` is gitignored (machine-specific). Two monitors — `eDP-1` (laptop) and `HDMI-A-1` (external). `SUPER+O` runs `scripts/external_only.sh` to disable laptop display; `SUPER+P` restores default layout. Autostart: waybar, dunst, hyprpaper, wlsunset, hypridle, `darkman run`. The startup hook also runs `dbus-update-activation-environment` and `systemctl --user start hyprland-session.target` — the latter pulls in `graphical-session.target` (`RefuseManualStart`) so `xdg-desktop-portal` can run. Without that target the portal never starts and portal-dependent features (file pickers, screen-share, app light/dark detection) silently break.

**Light/Dark theming**: Everything uses Catppuccin — **Latte** for light, **Mocha** for dark. [darkman](https://gitlab.com/WhyNotHugo/darkman) is the single source of truth (`darkman toggle` / `set dark|light`; sunrise/sunset driven by lat/lng in `.config/darkman/config.yaml`). On every mode change darkman runs each executable in `~/.local/share/darkman/` with the mode (`dark`/`light`) as `$1`:

- `gtk.sh` is the **master switch** — sets gsettings (`color-scheme`, `gtk-theme`, `icon-theme`), relinks `~/.config/gtk-4.0` CSS, and updates the GTK `settings.ini` files. Because the gtk xdg-desktop-portal reports the gsettings color-scheme, **ghostty and Zen follow automatically** (no per-app script). Ghostty needs `theme = light:Catppuccin Latte,dark:Catppuccin Mocha` in its config; this only works while the portal is running (see Hyprland note).
- `tmux.sh` re-themes running tmux servers live (sets `@catppuccin_flavour`, re-runs the catppuccin plugin, `refresh-client`). `tmux.conf` also picks the flavour from `darkman get` at launch via `if-shell`, before tpm loads the plugin.
- `lazygit.sh` repoints `~/.local/state/lazygit/theme.yml` (a symlink) at the Catppuccin **mergable preset** (lavender accent) for the mode — `.config/lazygit/themes/{latte,mocha}.yml`. `hyprland.lua` sets `LG_CONFIG_FILE=…/config.yml,…/state/lazygit/theme.yml` so lazygit merges the preset over the base config at launch (no live reload — only newly opened instances re-theme). The symlink lives outside the stowed (folded) `.config/lazygit` dir; `darkman run` at startup creates it.
- **Neovim** is not script-driven: `auto-dark-mode.nvim` polls the same system color-scheme and toggles `vim.o.background`; catppuccin is set up with `flavour = "auto"` + a `background = { light = "latte", dark = "mocha" }` map, so `require("catppuccin").load()` resolves the flavour from the background.

When adding a new app, prefer letting it follow the portal color-scheme; only add a `~/.local/share/darkman/*.sh` script if it can't.

**Packages**: `packages/pacman.txt` and `packages/aur.txt` list all managed packages. Edit these before running `install.sh` to add/remove software.

## Monitor Scripts

```bash
~/scripts/external_only.sh    # Disable laptop screen, use HDMI only
~/scripts/restore_default.sh  # Restore both monitors
```
