#!/bin/sh
# kubectl, kubectx, k9s (Arch extra repo).
set -e

if command -v kubectl >/dev/null 2>&1 && command -v kubectx >/dev/null 2>&1 && command -v k9s >/dev/null 2>&1; then
  echo "kubectl, kubectx, k9s already installed — skipping."
  exit 0
fi

if command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm kubectl kubectx k9s
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm kubectl kubectx k9s
else
  printf '%s\n' "Need yay or pacman to install kubectl, kubectx, k9s." >&2
  exit 1
fi

echo "Done: kubectl, kubectx, k9s"
