#!/bin/sh
# Install the Playwright MCP runtime that opencode's `playwright` MCP and
# `browser` agent depend on. The MCP *registration* lives in opencode.json
# (stowed by the opencode package); this fetches the pieces too large/mutable to
# commit:
#   - the pinned @playwright/mcp package (npx cache)
#   - the Chromium browser binaries (~/.cache/ms-playwright, hundreds of MB)
#
# Same policy as stealth/: browser binaries are never committed, only the step
# that installs them. Idempotent — re-running is a fast no-op once installed.
#
# Requires node/npx on PATH. This machine provides it via mise; there is no node
# install in these dotfiles yet, so we require it rather than install it.
set -eu

MCP_VERSION="0.0.79"   # keep in sync with the pin in opencode.json's mcp.playwright

if ! command -v npx >/dev/null 2>&1; then
  echo "install-playwright: npx not found. Run bin/install-mise.sh first" >&2
  echo "  (it installs mise + the pinned node@lts that provides npx), then re-run." >&2
  exit 1
fi

echo "==> Warming @playwright/mcp@${MCP_VERSION} (npx cache)"
npx -y "@playwright/mcp@${MCP_VERSION}" --help >/dev/null 2>&1 || true

echo "==> Installing the Chromium build it drives (-> ~/.cache/ms-playwright)"
# Prefer the browser build resolved inside the pinned MCP's dependency closure so
# versions align; fall back to a generic install if that form is unavailable.
npx -y --package "@playwright/mcp@${MCP_VERSION}" playwright install chromium \
  || npx -y playwright install chromium

echo "Playwright MCP runtime ready (browsers in ~/.cache/ms-playwright)."
