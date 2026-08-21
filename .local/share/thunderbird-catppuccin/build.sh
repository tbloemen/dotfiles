#!/bin/sh
# Build the Catppuccin Latte/Mocha Lavender theme addon for Thunderbird.
# Prints the path of the built .xpi.
#
# There is nothing to compile: an .xpi is a plain zip, and this theme is a
# single manifest.json carrying both palettes -- `theme` (Latte) and
# `dark_theme` (Mocha). Thunderbird's LightweightThemeConsumer listens on the
# "(-moz-system-dark-theme)" media query and re-picks between the two whenever
# the system color-scheme changes, so darkman drives it through the gtk portal
# (see gtk.sh) with no hook of our own and no restart.
#
# Unlike Firefox, Thunderbird ships xpinstall.signatures.required=false, so this
# unsigned local build installs as-is: Settings > Add-ons and Themes > gear icon
# > "Install Add-on From File...". There is no CLI for it.
#
# The output lands in the cache dir rather than next to the source, so the build
# artefact stays out of this (stow-folded, i.e. live) dotfiles directory.
#
# Editing the colors? Bump "version" in manifest.json before reinstalling --
# Thunderbird ignores a same-version reinstall.

src="$HOME/.local/share/thunderbird-catppuccin"
out="${XDG_CACHE_HOME:-$HOME/.cache}/thunderbird-catppuccin"
xpi="$out/catppuccin-auto-lavender.xpi"

mkdir -p "$out"
rm -f "$xpi"
cd "$src" || exit 1
zip -q "$xpi" manifest.json || exit 1

echo "$xpi"
