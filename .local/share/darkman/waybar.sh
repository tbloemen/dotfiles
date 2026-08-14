#!/bin/sh
# darkman hook: switch waybar between the Catppuccin Latte (light) and Mocha
# (dark) palettes, then refresh the custom/darkman indicator.
# darkman passes the current mode ("dark"/"light") as $1.
#
# style.css @imports colors.css (gitignored, created here). It's overwritten
# in place rather than symlinked so waybar's "reload_style_on_change" inotify
# watch — which follows @import targets — reliably fires on the file itself.

case "$1" in
dark)
  flavour="mocha"
  ;;
light)
  flavour="latte"
  ;;
*)
  echo "usage: $0 {dark|light}" >&2
  exit 1
  ;;
esac

cp "$HOME/.config/waybar/colors-$flavour.css" "$HOME/.config/waybar/colors.css"

# custom/darkman re-queries `darkman get` itself on signal 8 — this refreshes
# it on every mode change, not just the waybar toggle button itself (e.g.
# `darkman set`, sunrise/sunset).
#
# Only signal instances that have actually installed the handler. waybar
# catches every real-time signal, but not until its modules are up, and the
# default disposition of an RT signal is *terminate* — so signalling a waybar
# that is still starting kills it. At boot `darkman run` re-runs this hook
# within milliseconds of waybar launching (see the hyprland.start block in
# .config/hypr/hyprland.lua), which is exactly that window; a cold-cache boot
# widens it enough to lose the race, which is why waybar intermittently never
# appeared after a reboot.
#
# SIGRTMIN is a libc runtime value, not a compile-time constant -- glibc
# reserves signals 32-33 for NPTL and starts at 34, musl reserves 32-34 and
# starts at 35 -- so resolve the number via the shell instead of hardcoding it,
# falling back to glibc's numbering if this /bin/sh can't parse RT signal names.
rtsig=$(kill -l RTMIN+8 2>/dev/null)
case "$rtsig" in
'' | *[!0-9]*) rtsig=42 ;;
esac

# SigCgt in /proc/PID/status is the caught-signal mask: 16 hex digits, one bit
# per signal, bit N-1 for signal N. Test it in 32-bit halves -- the full 64-bit
# value is negative once the high bit is set, and >> on a negative is
# implementation-defined in shell arithmetic.
bit=$((rtsig - 1))
for pid in $(pgrep -x waybar); do
  cgt=$(awk '/^SigCgt:/ {print $2}' "/proc/$pid/status" 2>/dev/null)
  case "$cgt" in
  ????????????????) ;;
  *) continue ;;
  esac
  if [ "$bit" -ge 32 ]; then
    half=${cgt%????????}
    idx=$((bit - 32))
  else
    half=${cgt#????????}
    idx=$bit
  fi
  [ "$((0x$half >> idx & 1))" -eq 1 ] || continue
  kill -"$rtsig" "$pid" 2>/dev/null
done
