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
| Quickshell (bar, notifications) | `.config/quickshell/` |
| Kitty (terminal)      | `.config/kitty/`                           |
| Ghostty (terminal)    | `.config/ghostty/config.ghostty`           |
| Tmux                  | `.config/tmux/tmux.conf`                   |
| Neovim (LazyVim)      | `.config/nvim/`                            |
| Zsh                   | `.zshrc`                                    |
| Sesh (session mgr)    | `.config/sesh/sesh.toml`                   |
| Yazi (file manager)   | `.config/yazi/`                            |
| Darkman (light/dark)  | `.config/darkman/`, `.local/share/darkman/`|
| Notulen (meetings)    | `.config/notulen/config.toml`              |
| Thunderbird theme     | `.local/share/thunderbird-catppuccin/`     |

## Architecture Notes

**Shell**: Zsh with [antidote](https://github.com/mattmc3/antidote) for plugin management, starship prompt, fzf, and zoxide. Plugins are declared in `~/.zsh_plugins.txt` (not in this repo). Secrets are loaded on demand via `load_secrets` (autoloaded from `.zsh_autoload_functions/`), which unlocks Bitwarden CLI and exports API keys.

**Neovim**: LazyVim distribution with custom plugins in `.config/nvim/lua/plugins/`. Active LSPs: pyright + ruff (Python), tinymist (Typst), marksman (Markdown/Obsidian). Conform handles formatting, mason manages LSP/linter binaries.

**Tmux**: Prefix is `C-Space`. Sessions managed with sesh (fuzzy picker via `t`). TPM plugins include catppuccin theme, resurrect/continuum for session persistence, and vim-tmux-navigator.

**Hyprland**: Configured in **Lua** (`hyprland.lua`), not hyprctl syntax — monitors, binds, and autostart are declared through an `hl.*` API (`hl.monitor`, `hl.bind`, `hl.on("hyprland.start", ...)` + `hl.exec_cmd`). `monitors.conf` is gitignored (machine-specific). Two monitors — `eDP-1` (laptop) and `HDMI-A-1` (external). `SUPER+O` runs `scripts/external_only.sh` to disable laptop display; `SUPER+P` restores default layout. Autostart: quickshell (`qs`, which is also the notification daemon, the lock screen and the wallpaper), wlsunset, hypridle, `darkman run`. The startup hook also runs `dbus-update-activation-environment` and `systemctl --user start hyprland-session.target` — the latter pulls in `graphical-session.target` (`RefuseManualStart`) so `xdg-desktop-portal` can run. Without that target the portal never starts and portal-dependent features (file pickers, screen-share, app light/dark detection) silently break.

**`hyprctl dispatch` is Lua too** — this bites anything outside `hyprland.lua` that shells out to hyprctl (hypridle, quickshell, scripts). The argument is evaluated as Lua, so the old bare-keyword forms are undefined globals or outright syntax errors and fail silently: use `hyprctl dispatch 'hl.dsp.exit()'`, not `hyprctl dispatch exit`, and `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'`, not `hyprctl dispatch dpms off`. Two traps: `hyprctl eval` runs Lua but does **not** apply dispatchers, so it can't stand in for `dispatch`; and togglable `action` values are parsed from a **string**, with anything unrecognised — including an unquoted bare word, which is just a nil global — silently falling back to `toggle` rather than erroring. That fallback is why `hyprland.lua`'s startup dpms cycle worked for a while with unquoted `disabled`/`enabled`: two nils meant two toggles, which is coincidentally the same off/on. Per the wiki, prefer `hyprshutdown` over the `exit` dispatcher (it shuts the session down in order); `hyprland.lua`'s `SUPER+M` bind and the quickshell power menu both try it first and fall back to `hl.dsp.exit()`.

**Light/Dark theming**: Everything uses Catppuccin — **Latte** for light, **Mocha** for dark. [darkman](https://gitlab.com/WhyNotHugo/darkman) is the single source of truth (`darkman toggle` / `set dark|light`; sunrise/sunset driven by lat/lng in `.config/darkman/config.yaml`). On every mode change darkman runs each executable in `~/.local/share/darkman/` with the mode (`dark`/`light`) as `$1`:

- `gtk.sh` is the **master switch** — sets gsettings (`color-scheme`, `gtk-theme`, `icon-theme`), relinks `~/.config/gtk-4.0` CSS, and updates the GTK `settings.ini` files. Because the gtk xdg-desktop-portal reports the gsettings color-scheme, **ghostty and Zen follow automatically** (no per-app script). Ghostty needs `theme = light:Catppuccin Latte,dark:Catppuccin Mocha` in its config; this only works while the portal is running (see Hyprland note).
- **tmux** is not darkman-script-driven either: there is no `tmux.sh` hook. `tmux.conf` instead registers native tmux `client-dark-theme`/`client-light-theme` hooks (see `.config/tmux/tmux.conf`), which tmux fires itself when the terminal reports a color-scheme change — Ghostty relays the gtk xdg-desktop-portal's `color-scheme` (the same signal `gtk.sh` drives), so tmux ends up following darkman transitively rather than being invoked by it. Each hook sets `@catppuccin_flavor` (mocha/latte), then re-runs and reloads the catppuccin plugin (`@catppuccin_reset`) to pick up the new flavour, re-asserting a few options the reset clobbers (window style, separators, window text).
- `lazygit.sh` repoints `~/.local/state/lazygit/theme.yml` (a symlink) at the Catppuccin **mergable preset** (lavender accent) for the mode — `.config/lazygit/themes/{latte,mocha}.yml`. `hyprland.lua` sets `LG_CONFIG_FILE=…/config.yml,…/state/lazygit/theme.yml` so lazygit merges the preset over the base config at launch (no live reload — only newly opened instances re-theme). The symlink lives outside the stowed (folded) `.config/lazygit` dir; `darkman run` at startup creates it.
- `quickshell.sh` runs `qs ipc call darkman setMode <mode>`, pushing the mode into the bar's `Colors` singleton (`bar/Theme/Colors.qml`) through the `darkman` `IpcHandler` in `bar/shell.qml`; every color animates, so a toggle crossfades. On launch the bar seeds itself from `~/.cache/darkman/mode.txt`, so it needs no pre-run hook at startup. The bar's darkman pill (moon/sun) runs `darkman toggle` and is redrawn by this same push, whatever the source of the change (sunrise/sunset, `darkman set`).
- **btop** is not darkman-script-driven: btop reads its theme only at launch (no reload signal) *and* rewrites whatever config it loaded on exit (`save_config_on_exit = true`, which also resolves any symlinked theme path back to its real target — so the lazygit-style symlink-swap trick does **not** survive a btop quit). Instead there are two full configs, `btop_dark.conf` (mocha) and `btop_light.conf` (latte), differing only in `color_theme`, and `.zshrc` aliases `btop` to `btop -c …/btop_$(darkman get).conf` so each launch picks the current mode. All three configs define preset 4 as mem + proc only, which the bar's memory pill launches (`ghostty -e btop -c …/btop_$(darkman get).conf -p 4`). `btop.conf` remains as the fallback for non-aliased invocations. Caveat: each mode config self-rewrites on exit, so they can drift in any non-theme setting changed in only one mode.
- **Neovim** is not script-driven: `auto-dark-mode.nvim` polls the same system color-scheme and toggles `vim.o.background`; catppuccin is set up with `flavour = "auto"` + a `background = { light = "latte", dark = "mocha" }` map, so `require("catppuccin").load()` resolves the flavour from the background.
- **Thunderbird** is not script-driven either: the Catppuccin theme addon is built from `.local/share/thunderbird-catppuccin/manifest.json`, which carries *both* palettes — `theme` (Latte) and `dark_theme` (Mocha) — in one static addon. Gecko's `LightweightThemeConsumer` holds a listener on the `(-moz-system-dark-theme)` media query and re-picks between the two whenever the system color-scheme changes, so it follows darkman through the gtk portal, live and without a restart. Thunderbird has no CLI or IPC for switching themes, so installing is a one-off manual step: `sh ~/.local/share/thunderbird-catppuccin/build.sh` (zips the manifest into an .xpi under `~/.cache/`; unsigned is fine — Thunderbird ships `xpinstall.signatures.required=false`), then Settings → Add-ons and Themes → gear → "Install Add-on From File…". Editing the colors means bumping `version` in the manifest and reinstalling — a same-version reinstall is ignored. The ~20 keys under `theme_experiment` map Thunderbird-internal CSS variables (spaces bar, folder pane, calendar) onto theme keys; without them those surfaces are unthemeable.

When adding a new app, prefer letting it follow the portal color-scheme; only add a `~/.local/share/darkman/*.sh` script if it can't.

**Quickshell (bar)**: `qs` (no args) loads `.config/quickshell/shell.qml`, which loads `bar/shell.qml`: one bar per screen (`Variants` over `Quickshell.screens`), built from the pill modules in `bar/Modules/` (all on the shared `Pill.qml` chrome) with palette/sizing in `bar/Theme/`. The network pill opens the network card (`bar/NetworkCard.qml`, also `qs ipc call network toggleCard`), unfolding under the pill: current connection, a Wi-Fi radio toggle, and the scanned network list from `Quickshell.Networking` (shared state in `bar/Services/Net.qml`, which also turns on scanning only while a card is open). Known/open networks connect on click, new secured ones take an inline password, the connected one (or right click on a saved one) offers disconnect/forget. Right click on the pill toggles the Wi-Fi radio. Only one of the power menu / notification center / launcher / cards is open at a time — every opener calls `UiState.closePanels()` first. The power menu (`bar/PowerMenu.qml`) opens from the power pill (rightmost) or `SUPER+ESCAPE` (`qs ipc call powermenu toggle`): lock / suspend fire on click, log out / reboot / shut down are press-and-hold (`PowerMenuItem.qml`) instead of a confirmation dialog. Lock goes through `loginctl lock-session` (same path as hypridle's idle timeout); log out prefers `hyprshutdown` and falls back to `hyprctl dispatch 'hl.dsp.exit()'`. Keyboard focus comes from a `HyprlandFocusGrab`, not an exclusive layer keyboard focus — the latter makes Hyprland route pointer input to the menu too, which kills the bar. `hyprland.lua` disables Hyprland's layer animation for the `quickshell:powermenu` namespace since the menu animates itself.

**Cards (`bar/Card.qml`)**: the media, Bluetooth, audio and calendar cards share `Card.qml` — the network card's window/focus/animation chrome, parameterised by the `UiState` property that holds the open screen (`screenProp`), the layer namespace, and which edge of the pill to line up with (`align` + `anchorX`, fed from `Bar.qml`'s `*Anchor*` properties). Children go into a `ColumnLayout`. `Slider.qml` is the shared 0..1 slider.

**Media**: `bar/Services/Media.qml` picks the MPRIS player to show (`active`: one picked in the card's switcher until it closes, else the playing one, else the last one that played). The now-playing pill (`Modules/MediaIndicator.qml`, after the workspaces, only while a player exists) opens `bar/MediaCard.qml` (art, track, seek, transport, player switcher); right click plays/pauses. MPRIS doesn't push position, so it's polled once a second while the card is open. IPC: `qs ipc call media toggleCard|playPause|next|previous`. The media keys still go through `playerctl`. A new track on the playing player pops a toast through the OSD (`Osd.showTrack`, `kind: "track"` — `OsdWindow.qml` then shows art + title instead of a level bar), debounced since players send title/artist/art separately, and skipped while the card is open.

**Bluetooth**: `bar/Services/Bt.qml` wraps `Quickshell.Bluetooth` (default adapter, devices sorted connected → paired → named nearby ones, discovery on only while a card is open, like the Wi-Fi scan). The pill (`Modules/BluetoothIndicator.qml`, left of the network pill, hidden without an adapter) opens `bar/BluetoothCard.qml`; right click powers the adapter. In the card a click connects/disconnects a paired device or pairs a new one (then trusts and connects it); right click a paired one for disconnect/forget. PIN/passkey prompts still come from `blueman-applet`, the registered BlueZ agent — keep it running. IPC: `qs ipc call bluetooth toggleCard`.

**Launcher (quickshell, replaces `rofi -show drun`)**: `SUPER+SPACE` runs `qs ipc call launcher toggle`, opening `bar/Launcher.qml` centered under the bar on the focused monitor (same focus-grab setup as the power menu, and it closes the other panels via `UiState.closePanels()`). The model is `bar/Services/Apps.qml`: `DesktopEntries.applications` minus `NoDisplay`, a small fuzzy matcher (name > generic name/keywords > comment; prefix > word start > substring > subsequence), and launch counts persisted under `Quickshell.statePath("launcher.json")` (outside the repo) that rank an empty query and break near-ties. `DesktopEntry.execute()` ignores `Terminal=true`, so those entries are wrapped in `ghostty -e`.

**Lock screen (quickshell, replaces hyprlock)**: everything locks through logind (`loginctl lock-session` from hypridle's timeout, `before_sleep_cmd`, the power menu), and hypridle's `lock_cmd` runs `qs ipc call lock lock`, which only counts if it answers `locked` — otherwise (qs down, or a config without the handler) it falls back to `hyprlock`, so keep that package installed. `bar/LockScreen.qml` owns the `WlSessionLock` and a `PamContext` on the stock `login` service (same stack as `/etc/pam.d/hyprlock`, so pam_faillock's lockout after repeated wrong passwords applies); it keeps the password and status shared, so every monitor's `bar/LockSurface.qml` shows the same dots and you can type on whichever is focused. The surface is a plain `Item`, so it can be previewed in a `FloatingWindow` with a mock context without actually locking. The background is the desktop wallpaper (`Services/Wallpaper.qml`) blurred and dimmed. `hyprland.lua` sets `misc.allow_session_lock_restore` so that if qs dies while locked, a new locker can take over: from a TTY, `hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'`, then unlock in hyprlock.

**Wallpaper (quickshell, replaces hyprpaper)**: `bar/WallpaperWindow.qml` is a per-screen `PanelWindow` on the background layer. `bar/Services/Wallpaper.qml` picks `~/wallpapers/active/{light,dark}.png` from `Colors.mode`, so it follows darkman with no hook (there used to be a `hyprpaper.sh`), and keeps both frames loaded with the light one fading over the dark, so a mode change crossfades at once, in step with the bar's colors (both use `Metrics.animTheme`). `~/wallpapers/active` is a symlink to a `wallpapers/<name>/` directory holding `light.png` + `dark.png`; after repointing it, run `qs ipc call wallpaper reload`. Images decode at screen size (`sourceSize`), not their full resolution. The lock screen uses the same source.

**Notifications (quickshell, replaces dunst)**: `bar/Services/Notifs.qml` owns the `NotificationServer` (`org.freedesktop.Notifications`); `shell.qml` touches the singleton on startup so the D-Bus name is claimed at launch rather than lazily. Every notification is tracked, and `server.trackedNotifications` *is* the history (capped at 20, oldest dismissed) — a toast is only an id in `Notifs.popups`, so hiding one never closes the notification. Timeouts fall back to dunst's old per-urgency values (low 4s, normal 6s, critical sticky) when the app leaves it to the server. Toasts (`NotificationPopups.qml`) go top-right on whichever monitor was focused when the latest one arrived; the history panel (`NotificationCenter.qml`, PowerMenu-style focus grab, only one of the two open at a time) opens from the bell pill or `SUPER+SHIFT+N`. Pill right-click toggles DND (toasts suppressed except critical, still recorded). Cards (`NotificationCard.qml`): left click = default action, middle = clear toasts, right = dismiss. IPC: `qs ipc call notifications toggleCenter|clearPopups|clearAll|toggleDnd`; `SUPER+N` is `clearPopups`. Because it reads `Colors`, it follows darkman with no hook. Keep the `dunst` package uninstalled: its D-Bus activation file would auto-start dunst whenever qs isn't holding the name (e.g. during a qs restart).

**OSD**: `bar/Services/Osd.qml` + `OsdWindow.qml`. Volume is observed from the default Pipewire sink (keys, pill scroll, pavucontrol all show it; changes in the first second after a sink appears are ignored to avoid a startup flash). Brightness has no Quickshell service and sysfs doesn't emit inotify, so the brightness binds in `hyprland.lua` run `qs ipc call osd brightness` after `brightnessctl`, and the OSD reads the level back from `brightnessctl -m`. `hyprland.lua` disables layer animations for the `quickshell:(notifications|notifcenter|osd|networkcard)` namespaces too.

**Notulen (meeting recorder)**: `SUPER+R` runs `notulen toggle` in a floating ghostty window (`--class=notulen`, matched by the `float-notulen` window rule) — press once to start recording, again to stop and file the note. The code lives in its own repo at `~/Documents/Development/notulen` and installs with `cargo install --path . --root ~/.local`; only the config is stowed from here. It records two tracks (mic + the default sink's `.monitor`), transcribes with `whisper-cli`, diarizes the room track, summarizes with a local ollama model, and writes a note into an Obsidian vault directory. Needs `ollama` running (`systemctl enable --now ollama`).

**Packages**: `packages/pacman.txt` and `packages/aur.txt` list all managed packages. Edit these before running `install.sh` to add/remove software.

## Monitor Scripts

```bash
~/scripts/external_only.sh    # Disable laptop screen, use HDMI only
~/scripts/restore_default.sh  # Restore both monitors
```
