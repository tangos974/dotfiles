#!/bin/sh
# Install Mullvad Browser and stow the Hypr / uwsm / omarchy-bin packages that
# wire it in as the default browser.
#
# The actual config bits are committed once and live as stow targets:
#   hypr/.config/hypr/bindings.conf    (`$browser`, SUPER+SHIFT+B, +RETURN)
#   uwsm/.config/uwsm/default          (`export BROWSER=mullvad-browser`)
#   omarchy-bin/.local/share/omarchy-overrides/bin/omarchy-launch-{,or-focus-}webapp
# This script does NOT mutate any tracked file — it only installs the package,
# stows the configs, and refreshes runtime settings.

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

. "$SCRIPT_DIR/dotfiles-stow.sh"

install_browser() {
  if pacman -Qq mullvad-browser-bin >/dev/null 2>&1; then
    echo "mullvad-browser-bin already installed — skipping."
    return 0
  fi
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm mullvad-browser-bin
  else
    echo "yay not found. Install yay first, or install mullvad-browser-bin manually." >&2
    exit 1
  fi
}

set_xdg_default_browser() {
  # Idempotent local setting; often fails when uwsm/session sets $BROWSER, but
  # we still set BROWSER via the stowed uwsm/default file.
  xdg-settings set default-web-browser mullvad-browser.desktop || true
}

main() {
  install_browser
  set_xdg_default_browser
  stow_pkg hypr
  stow_pkg uwsm
  stow_pkg omarchy-bin

  hyprctl reload >/dev/null 2>&1 || true

  echo
  echo "Done."
  echo "  Browser:  Mullvad Browser (set as default via xdg-settings + uwsm BROWSER)."
  echo "  Bindings: SUPER+SHIFT+B and SUPER+SHIFT+RETURN (committed in hypr/bindings.conf)."
  echo "  Stow:     hypr / uwsm / omarchy-bin (conflicts auto-backed-up to ~/.local/state/dotfiles-stow-backups/)."
}

main "$@"
