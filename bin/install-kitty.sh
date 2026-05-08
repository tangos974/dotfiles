#!/bin/sh

if command -v kitty >/dev/null 2>&1; then
  echo "kitty already installed — skipping."
  exit 0
fi

yay -S --noconfirm --needed kitty
