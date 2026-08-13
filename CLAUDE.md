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
| Notulen (meetings)    | `.config/notulen/config.toml`              |

## Architecture Notes

**Shell**: Zsh with [antidote](https://github.com/mattmc3/antidote) for plugin management, starship prompt, fzf, and zoxide. Plugins are declared in `~/.zsh_plugins.txt` (not in this repo). Secrets are loaded on demand via `load_secrets` (autoloaded from `.zsh_autoload_functions/`), which unlocks Bitwarden CLI and exports API keys.

**Neovim**: LazyVim distribution with custom plugins in `.config/nvim/lua/plugins/`. Active LSPs: pyright + ruff (Python), tinymist (Typst), marksman (Markdown/Obsidian). Conform handles formatting, mason manages LSP/linter binaries.

**Tmux**: Prefix is `C-Space`. Sessions managed with sesh (fuzzy picker via `t`). TPM plugins include catppuccin theme, resurrect/continuum for session persistence, and vim-tmux-navigator.

**Hyprland**: Configured in **Lua** (`hyprland.lua`), not hyprctl syntax — monitors, binds, and autostart are declared through an `hl.*` API (`hl.monitor`, `hl.bind`, `hl.on("hyprland.start", ...)` + `hl.exec_cmd`). `monitors.conf` is gitignored (machine-specific). Two monitors — `eDP-1` (laptop) and `HDMI-A-1` (external). `SUPER+O` runs `scripts/external_only.sh` to disable laptop display; `SUPER+P` restores default layout. Autostart: waybar, dunst, hyprpaper, wlsunset, hypridle, `darkman run`. The startup hook also runs `dbus-update-activation-environment` and `systemctl --user start hyprland-session.target` — the latter pulls in `graphical-session.target` (`RefuseManualStart`) so `xdg-desktop-portal` can run. Without that target the portal never starts and portal-dependent features (file pickers, screen-share, app light/dark detection) silently break.

**Light/Dark theming**: Everything uses Catppuccin — **Latte** for light, **Mocha** for dark. [darkman](https://gitlab.com/WhyNotHugo/darkman) is the single source of truth (`darkman toggle` / `set dark|light`; sunrise/sunset driven by lat/lng in `.config/darkman/config.yaml`). On every mode change darkman runs each executable in `~/.local/share/darkman/` with the mode (`dark`/`light`) as `$1`:

- `gtk.sh` is the **master switch** — sets gsettings (`color-scheme`, `gtk-theme`, `icon-theme`), relinks `~/.config/gtk-4.0` CSS, and updates the GTK `settings.ini` files. Because the gtk xdg-desktop-portal reports the gsettings color-scheme, **ghostty and Zen follow automatically** (no per-app script). Ghostty needs `theme = light:Catppuccin Latte,dark:Catppuccin Mocha` in its config; this only works while the portal is running (see Hyprland note).
- **tmux** is not darkman-script-driven either: there is no `tmux.sh` hook. `tmux.conf` instead registers native tmux `client-dark-theme`/`client-light-theme` hooks (see `.config/tmux/tmux.conf`), which tmux fires itself when the terminal reports a color-scheme change — Ghostty relays the gtk xdg-desktop-portal's `color-scheme` (the same signal `gtk.sh` drives), so tmux ends up following darkman transitively rather than being invoked by it. Each hook sets `@catppuccin_flavor` (mocha/latte), then re-runs and reloads the catppuccin plugin (`@catppuccin_reset`) to pick up the new flavour, re-asserting a few options the reset clobbers (window style, separators, window text).
- `lazygit.sh` repoints `~/.local/state/lazygit/theme.yml` (a symlink) at the Catppuccin **mergable preset** (lavender accent) for the mode — `.config/lazygit/themes/{latte,mocha}.yml`. `hyprland.lua` sets `LG_CONFIG_FILE=…/config.yml,…/state/lazygit/theme.yml` so lazygit merges the preset over the base config at launch (no live reload — only newly opened instances re-theme). The symlink lives outside the stowed (folded) `.config/lazygit` dir; `darkman run` at startup creates it.
- `waybar.sh` signals waybar (`pkill -RTMIN+8 waybar`) to refresh the `custom/darkman` module — a click-to-toggle indicator (moon/sun icon) that runs `darkman toggle` and re-queries `darkman get` on signal 8. Lets the module react to mode changes from any source (sunrise/sunset, `darkman set`), not just its own click.
- `dunst.sh` copies `.config/dunst/colors-{latte,mocha}.conf` to `.config/dunst/dunstrc.d/99-colors.conf` and runs `dunstctl reload`. dunst has no include directive, so per-mode colors ride on its drop-in mechanism (`dunstrc.d/*.conf` is read after `dunstrc`, last wins — the `99-` prefix guarantees the fragment sorts last). The fragment carries only the four colors that change (`frame_color` + `background`/`foreground`/`highlight` per urgency); `dunstrc` keeps the Mocha values as a fallback and owns everything else (`separator_color = "frame"` follows `frame_color`, timeouts stay per-urgency). `dunstrc.d/` is generated, so it's gitignored via `.config/dunst/.gitignore` — the folded stow symlink means the hook writes into this repo, same as waybar's `colors.css`. The reload is best-effort: at startup `darkman run` may fire before dunst is up, but the drop-in is already on disk by then.
- **btop** is not darkman-script-driven: btop reads its theme only at launch (no reload signal) *and* rewrites whatever config it loaded on exit (`save_config_on_exit = true`, which also resolves any symlinked theme path back to its real target — so the lazygit-style symlink-swap trick does **not** survive a btop quit). Instead there are two full configs, `btop_dark.conf` (mocha) and `btop_light.conf` (latte), differing only in `color_theme`, and `.zshrc` aliases `btop` to `btop -c …/btop_$(darkman get).conf` so each launch picks the current mode. `btop.conf` remains as the fallback for non-aliased invocations. Caveat: each mode config self-rewrites on exit, so they can drift in any non-theme setting changed in only one mode.
- **Neovim** is not script-driven: `auto-dark-mode.nvim` polls the same system color-scheme and toggles `vim.o.background`; catppuccin is set up with `flavour = "auto"` + a `background = { light = "latte", dark = "mocha" }` map, so `require("catppuccin").load()` resolves the flavour from the background.

When adding a new app, prefer letting it follow the portal color-scheme; only add a `~/.local/share/darkman/*.sh` script if it can't.

**Notulen (meeting recorder)**: `SUPER+R` runs `notulen toggle` in a floating ghostty window (`--class=notulen`, matched by the `float-notulen` window rule) — press once to start recording, again to stop and file the note. The code lives in its own repo at `~/Documents/Development/notulen` and installs with `cargo install --path . --root ~/.local`; only the config is stowed from here. It records two tracks (mic + the default sink's `.monitor`), transcribes with `whisper-cli`, diarizes the room track, summarizes with a local ollama model, and writes a note into an Obsidian vault directory. Needs `ollama` running (`systemctl enable --now ollama`).

**Packages**: `packages/pacman.txt` and `packages/aur.txt` list all managed packages. Edit these before running `install.sh` to add/remove software.

## Monitor Scripts

```bash
~/scripts/external_only.sh    # Disable laptop screen, use HDMI only
~/scripts/restore_default.sh  # Restore both monitors
```
