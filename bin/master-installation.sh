#!/bin/sh
#
# Full dotfiles bootstrap for Omarchy + Arch. Clone this repo to ~/dotfiles, then run:
#   ./bin/master-installation.sh
#
# Requires: yay (or omarchy AUR helpers where scripts support them), sudo for preload
# and optional package removal. Some steps need a network (webapp icons).

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

[ -d "$DOTFILES_DIR" ] || die "Expected dotfiles at ${DOTFILES_DIR} (parent of bin/)."

. "$SCRIPT_DIR/dotfiles-stow.sh"

echo "==> stow (package)"
"$SCRIPT_DIR/install-stow.sh"

echo "==> Browser (Mullvad) + stow hypr / uwsm / omarchy-bin"
"$SCRIPT_DIR/install-mullvad-browser.sh"

echo "==> Stow waybar"
stow_pkg waybar

echo "==> Bash (~/.bashrc)"
"$SCRIPT_DIR/install-bash.sh"

echo "==> Terminal: Kitty + tree"
"$SCRIPT_DIR/install-kitty.sh"
"$SCRIPT_DIR/install-tree.sh"

echo "==> Kubernetes (kubectl, kubectx, k9s)"
"$SCRIPT_DIR/install-kubernetes-tools.sh"

echo "==> Jolt (battery / power TUI)"
"$SCRIPT_DIR/install-jolt.sh"

echo "==> Vortix (VPN TUI)"
"$SCRIPT_DIR/install-vortix.sh"

echo "==> Ghostty (Omarchy terminal install + dotfiles config)"
"$SCRIPT_DIR/install-ghostty.sh"

echo "==> Stow systemd user overrides (Ghostty service)"
stow_pkg systemd-user
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user try-restart app-com.mitchellh.ghostty.service 2>/dev/null || true
fi

echo "==> Preload daemon (AUR + system service)"
"$SCRIPT_DIR/install-preload.sh"

echo "==> Remove chat/media packages (see script for list)"
"$SCRIPT_DIR/remove-chat-and-media-apps.sh"

echo "==> Web apps (Deezer, Yahoo Mail) + Hypr bindings"
"$SCRIPT_DIR/install-deezer-webapp.sh"
"$SCRIPT_DIR/install-yahoo-mail-webapp.sh"

echo "==> Mullvad profile chrome (ok to skip until profiles exist)"
"$SCRIPT_DIR/setup-mullvad-webapp-profile.sh" ||
  printf '%s\n' "  Note: run setup-mullvad-webapp-profile.sh after creating the WebApps profile in Mullvad." >&2
"$SCRIPT_DIR/setup-mullvad-default-profiles.sh" ||
  printf '%s\n' "  Note: run setup-mullvad-default-profiles.sh after Mullvad has created profiles." >&2

echo "==> Hypr exec-once helpers -> ~/"
for f in adapt-workspaces.sh watch-monitor-events.sh; do
  ln -sf "$SCRIPT_DIR/$f" "$HOME/$f"
done
chmod +x "$SCRIPT_DIR/adapt-workspaces.sh" "$SCRIPT_DIR/watch-monitor-events.sh" 2>/dev/null || true

echo
echo "Master installation finished."
