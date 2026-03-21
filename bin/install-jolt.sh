#!/bin/sh
# Jolt — TUI battery and power monitor (Arch extra).
set -e

if command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm jolt
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm jolt
else
  printf '%s\n' "Need yay or pacman." >&2
  exit 1
fi

echo "Done: jolt (run: jolt, or right-click the Waybar battery icon)"
