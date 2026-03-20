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

# Stow refuses to replace a regular file with a symlink. Omarchy (or manual copies) often
# ship the same paths as plain files — move them aside like *.before-stow elsewhere.
backup_stow_file_conflicts() {
  pkg="$1"
  pkg_root="${DOTFILES_DIR}/${pkg}"
  prefix="${pkg_root}/"
  [ -d "$pkg_root" ] || return 0
  find "$pkg_root" -type f | while IFS= read -r src; do
    rel="${src#$prefix}"
    target="${HOME}/${rel}"
    if [ -e "$target" ] && [ ! -L "$target" ] && [ ! -e "${target}.before-stow" ]; then
      mv "$target" "${target}.before-stow"
      printf 'Backed up conflicting file for stow: %s -> %s.before-stow\n' "$target" "$target"
    fi
  done
}

stow_pkg() {
  pkg="$1"
  [ -d "${DOTFILES_DIR}/${pkg}" ] || return 0
  backup_stow_file_conflicts "$pkg"
  (cd "$DOTFILES_DIR" && stow -v -t "$HOME" "$pkg")
}

echo "==> stow (package)"
"$SCRIPT_DIR/install-stow.sh"

echo "==> Browser (Mullvad) + stow hypr / uwsm / omarchy-bin"
"$SCRIPT_DIR/install-mullvad-browser.sh"

echo "==> Stow waybar"
stow_pkg waybar

echo "==> Terminal: Kitty + tree"
"$SCRIPT_DIR/install-kitty.sh"
"$SCRIPT_DIR/install-tree.sh"

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
