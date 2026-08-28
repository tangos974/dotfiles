#!/bin/sh
# Configure OpenCode from the dotfiles: stow the config package and wire the
# stealth-fetch skill so OpenCode's native skill loader discovers it.
#
# OpenCode itself (the `opencode` binary) is installed separately — this only
# manages configuration for an already-installed OpenCode.
set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=dotfiles-stow.sh
. "$SCRIPT_DIR/dotfiles-stow.sh"

# opencode.json / tui.json / mcp/ / prompts/ -> ~/.config/opencode/
stow_pkg opencode

# Install the Playwright MCP runtime (node package + Chromium binaries) that the
# `playwright-headless` MCP / `browser` agent need. Non-fatal: the config is
# still valid without it, and browsers may already be installed.
"$SCRIPT_DIR/install-playwright.sh" ||
  echo "  Note: playwright runtime not installed; rerun bin/install-playwright.sh once node/npx is available." >&2

# NOTE: the `stealth` MCP is a REMOTE server hosted in the homelab (Camoufox in a
# container). Nothing to install here — see ~/Homelab/stealth_browser_todo.md.
# Flip mcp.stealth.enabled + its url in opencode.json once that service is up.

echo "OpenCode config stowed."
