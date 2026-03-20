#!/bin/sh
# Stow bash/.bashrc -> ~/.bashrc (Omarchy-aware rc lives in dotfiles).
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

[ -d "${DOTFILES_DIR}/bash" ] || {
  printf '%s\n' "Expected ${DOTFILES_DIR}/bash (bash package)." >&2
  exit 1
}

command -v stow >/dev/null 2>&1 || "$SCRIPT_DIR/install-stow.sh"

. "$SCRIPT_DIR/dotfiles-stow.sh"
stow_pkg bash

echo "Done. ~/.bashrc -> ${DOTFILES_DIR}/bash/.bashrc"
