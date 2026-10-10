#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

# Install packages from pacman
if [[ -f "$DOTFILES_DIR/packages/pacman.txt" ]]; then
  echo "Installing pacman packages..."
  cat packages/pacman.txt | sudo pacman -Syu --needed -
fi

# Install yay if missing
if ! command -v yay &>/dev/null; then
  echo "Installing yay..."
  sudo pacman -S --needed base-devel git
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
fi

# Install AUR packages with yay
if [[ -f "$DOTFILES_DIR/packages/aur.txt" ]]; then
  echo "Installing AUR packages..."
  cat packages/aur.txt | yay -Syu --needed -
fi

# Make sure stow is installed
if ! command -v stow &>/dev/null; then
  echo "📦 Installing stow..."
  sudo pacman -S --needed stow
fi

echo "✅ Package installation complete."

# Pin the settings btop rewrites on exit, so they don't show up as changes
git -C "$DOTFILES_DIR" config filter.btop-volatile.clean \
  "sed -E 's/^shown_boxes = .*/shown_boxes = \"cpu mem net proc\"/; s/^proc_sorting = .*/proc_sorting = \"cpu lazy\"/'"
git -C "$DOTFILES_DIR" config filter.btop-volatile.smudge cat

# GTK font: GTK on Wayland reads it from gsettings (dconf), and nothing else
# sets it. Theme, icons and cursor are set by the darkman hooks.
gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10'

# Catppuccin folder colour for Papirus. Papirus-Light and -Dark share the
# folder icons, so this covers both; papirus-folders-catppuccin-git's pacman
# hook re-applies it after every papirus-icon-theme upgrade.
sudo papirus-folders -C cat-mocha-mauve --theme Papirus-Dark

# Run stow on everything
echo "🔗 Symlinking dotfiles with stow..."
cd "$DOTFILES_DIR"
stow --target="$HOME" .

echo "✅ Dotfiles installation complete."
