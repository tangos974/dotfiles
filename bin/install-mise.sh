#!/bin/sh
# Install mise (runtime version manager) and materialize the pinned tools.
#
# The tool pins live in the mise/ package (~/.config/mise/config.toml, stowed
# here) — node@lts, go, python, uv. Shell activation is already in
# bash/.bashrc. node/npx from here is what the Playwright MCP needs
# (see install-playwright.sh), so this must run before setup-opencode.sh.
#
# Idempotent: skips the install if mise is present; `mise install` is a no-op
# for tools already at the pinned version.
set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"   # stow_pkg reads this
# shellcheck source=dotfiles-stow.sh
. "$SCRIPT_DIR/dotfiles-stow.sh"

if ! command -v mise >/dev/null 2>&1; then
  echo "==> Installing mise"
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm mise
  elif command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm mise
  else
    curl -fsSL https://mise.run | sh
  fi
fi

# Pinned tool versions -> ~/.config/mise/config.toml
stow_pkg mise

echo "==> Installing pinned tools (mise install)"
mise install

echo "mise ready; node -> $(mise current node 2>/dev/null || echo '(lts)')."
