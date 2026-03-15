#!/bin/sh

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Dotfiles mngmt
"$SCRIPT_DIR/install-stow.sh"

# Terminal
"$SCRIPT_DIR/install-kitty.sh"

# Terminal utils
"$SCRIPT_DIR/install-tree.sh"

