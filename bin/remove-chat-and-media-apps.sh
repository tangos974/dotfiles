#!/usr/bin/env bash

set -euo pipefail

packages=(
  signal-desktop
  spotify
  1password
  1password-beta
)

to_remove=()
for pkg in "${packages[@]}"; do
  if pacman -Q "$pkg" >/dev/null 2>&1; then
    to_remove+=("$pkg")
  fi
done

if ((${#to_remove[@]} == 0)); then
  echo "No matching packages are installed."
  exit 0
fi

echo "Removing: ${to_remove[*]}"
sudo pacman -Rns --noconfirm "${to_remove[@]}"

