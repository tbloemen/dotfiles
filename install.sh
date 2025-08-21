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

# Run stow on everything
echo "🔗 Symlinking dotfiles with stow..."
cd "$DOTFILES_DIR"
stow --target="$HOME" .

echo "✅ Dotfiles installation complete."
