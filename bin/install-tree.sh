#!/bin/sh

if command -v tree >/dev/null 2>&1; then
  echo "tree already installed — skipping."
  exit 0
fi

yay -S --needed --noconfirm tree
