#!/usr/bin/env bash
#
# Install Ghostty via Omarchy, replace Alacritty as default terminal, enable
# user preload (systemd), keep daemon alive after last window closes, and use
# `ghostty +new-window` for default launches (desktop entry + xdg-terminal-exec).

set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
GHOSTTY_DESKTOP_USER="${HOME}/.local/share/applications/com.mitchellh.ghostty.desktop"
LIVE_GHOSTTY_CONFIG="${HOME}/.config/ghostty/config"

# shellcheck source=dotfiles-stow.sh
. "${SCRIPT_DIR}/dotfiles-stow.sh"

stow_ghostty_omarchy_integration() {
  if [ ! -d "${DOTFILES_DIR}/omarchy-bin/.local/share/omarchy-overrides/bin" ] ||
    [ ! -f "${DOTFILES_DIR}/omarchy/.config/omarchy/extensions/menu.sh" ]; then
    return 0
  fi
  mkdir -p "${HOME}/.config/omarchy/extensions"
  stow_pkg omarchy-bin
  stow_pkg omarchy
}

ensure_ghostty_config() {
  mkdir -p "${HOME}/.config/ghostty"
  stow_pkg ghostty
  if [ ! -f "$LIVE_GHOSTTY_CONFIG" ] && [ -n "${OMARCHY_PATH:-}" ] && [ -f "${OMARCHY_PATH}/config/ghostty/config" ]; then
    cp "${OMARCHY_PATH}/config/ghostty/config" "$LIVE_GHOSTTY_CONFIG"
  fi
  if [ -f "$LIVE_GHOSTTY_CONFIG" ] && ! grep -q '^quit-after-last-window-closed' "$LIVE_GHOSTTY_CONFIG"; then
    printf '\n# Keep preload instance alive after last window closes\nquit-after-last-window-closed = false\n' >> "$LIVE_GHOSTTY_CONFIG"
  fi
}

install_desktop_override() {
  mkdir -p "${HOME}/.local/share/applications"
  cat >"${GHOSTTY_DESKTOP_USER}" <<'EOF'
[Desktop Entry]
Version=1.0
Name=Ghostty
Type=Application
Comment=A terminal emulator
TryExec=/usr/bin/ghostty
Exec=/usr/bin/ghostty --gtk-single-instance=true +new-window
Icon=com.mitchellh.ghostty
Categories=System;TerminalEmulator;
Keywords=terminal;tty;pty;
StartupNotify=true
StartupWMClass=com.mitchellh.ghostty
Terminal=false
Actions=new-window;
X-GNOME-UsesNotifications=true
X-TerminalArgExec=-e
X-TerminalArgTitle=--title=
X-TerminalArgAppId=--class=
X-TerminalArgDir=--working-directory=
X-TerminalArgHold=--wait-after-command
DBusActivatable=true
X-KDE-Shortcuts=Ctrl+Alt+T

[Desktop Action new-window]
Name=New Window
Exec=/usr/bin/ghostty --gtk-single-instance=true +new-window
EOF
  chmod +x "${GHOSTTY_DESKTOP_USER}"
}

main() {
  if ! command -v omarchy-install-terminal >/dev/null 2>&1; then
    echo "omarchy-install-terminal not found. Is Omarchy PATH set?" >&2
    exit 1
  fi

  ensure_ghostty_config
  stow_ghostty_omarchy_integration
  if command -v ghostty >/dev/null 2>&1; then
    echo "Ghostty already installed — skipping omarchy-install-terminal."
  else
    omarchy-install-terminal ghostty
  fi
  install_desktop_override

  systemctl --user enable --now app-com.mitchellh.ghostty.service

  if command -v omarchy-pkg-drop >/dev/null 2>&1; then
    omarchy-pkg-drop alacritty || true
  fi

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
  command -v hyprctl >/dev/null 2>&1 && hyprctl reload 2>/dev/null || true
  command -v omarchy-restart-terminal >/dev/null 2>&1 && omarchy-restart-terminal 2>/dev/null || true

  echo
  echo "Done."
  echo "  Default terminal: Ghostty (xdg-terminals.list via omarchy-install-terminal)"
  echo "  Preload: systemctl --user enable --now app-com.mitchellh.ghostty.service"
  echo "  Config: quit-after-last-window-closed = false (~/.config/ghostty/config)"
  echo "  Desktop: ${GHOSTTY_DESKTOP_USER} (Exec uses +new-window)"
  echo "  Omarchy: stow omarchy-bin + omarchy (Ghostty menu + presentation terminal) if present in dotfiles."
  echo "  Removed alacritty package if omarchy-pkg-drop succeeded."
}

main "$@"
