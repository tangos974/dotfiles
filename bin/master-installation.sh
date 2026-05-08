#!/bin/sh
#
# Full dotfiles bootstrap for Omarchy + Arch. Clone this repo to ~/dotfiles, then run:
#   ./bin/master-installation.sh
#
# Idempotent: every step short-circuits if already done. Re-run after pulling
# upstream to re-stow configs and apply any new packages.
#
# Phases:
#   0) Prerequisites — install GNU Stow
#   1) Packages + base config stows
#   2) Per-feature setup (keyboard layouts, ghostty preload, lid/sleep, preload daemon)
#   3) Webapps + Mullvad profiles (policies + per-profile configs)
#   4) Optional cleanup (uninstall undesired packages)
#
# Each install-*.sh installs a single tool. Each setup-*.sh / stow-*.sh
# configures something already installed (no package install). See README.md.

# set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

[ -d "$DOTFILES_DIR" ] || die "Expected dotfiles at ${DOTFILES_DIR} (parent of bin/)."

# shellcheck source=dotfiles-stow.sh
. "$SCRIPT_DIR/dotfiles-stow.sh"

# ---------------------------------------------------------------------------
# 0) Prerequisites
# ---------------------------------------------------------------------------

echo "==> [0/4] Prerequisites"
echo "  -> GNU Stow"
"$SCRIPT_DIR/install-stow.sh"

# ---------------------------------------------------------------------------
# 1) Packages + base config stows
#    Each script installs its tool (skipping if already present) and stows the
#    matching dotfiles package(s).
# ---------------------------------------------------------------------------

echo "==> [1/4] Packages and base config stows"
echo "  -> Bash dotfiles (~/.bashrc)"
"$SCRIPT_DIR/stow-bash.sh"

echo "  -> Mullvad Browser (default browser; stows hypr / uwsm / omarchy-bin)"
"$SCRIPT_DIR/install-mullvad-browser.sh"

echo "  -> Waybar config"
stow_pkg waybar

echo "  -> Terminals (Kitty, Ghostty)"
"$SCRIPT_DIR/install-kitty.sh"
"$SCRIPT_DIR/install-ghostty.sh"

echo "  -> CLI tools (tree, kubectl/kubectx/k9s, jolt, vortix)"
"$SCRIPT_DIR/install-tree.sh"
"$SCRIPT_DIR/install-kubernetes-tools.sh"
"$SCRIPT_DIR/install-jolt.sh"
"$SCRIPT_DIR/install-vortix.sh"

# ---------------------------------------------------------------------------
# 2) Per-feature setup (depends on configs already stowed by phase 1)
# ---------------------------------------------------------------------------

echo "==> [2/4] Per-feature setup"

echo "  -> Keyboard layout selector (UK / US / FR + gum TUI)"
"$SCRIPT_DIR/setup-keyboard-layouts.sh"

echo "  -> Ghostty preload (systemd user service override)"
stow_pkg systemd-user
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload
  # systemctl --user try-restart app-com.mitchellh.ghostty.service 2>/dev/null || true
  # We don't want to restart the terminal if itś the one running the script
fi

echo "  -> systemd-logind lid + sleep drop-ins (suspend-then-hibernate)"
"$SCRIPT_DIR/setup-systemd-lid-sleep.sh"

echo "  -> Preload daemon (system-wide AUR readahead service)"
"$SCRIPT_DIR/install-preload-daemon.sh"

echo "  -> Hyprland exec-once helpers (-> ~/.local/bin/)"
mkdir -p "$HOME/.local/bin"
for f in adapt-workspaces.sh watch-monitor-events.sh; do
  ln -sf "$SCRIPT_DIR/$f" "$HOME/.local/bin/$f"
  chmod +x "$SCRIPT_DIR/$f" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# 3) Webapps + Mullvad profiles
#    Policies require sudo. Missing profiles are created automatically.
# ---------------------------------------------------------------------------

echo "==> [3/4] Webapps + Mullvad profiles"
echo "  -> Webapps (Deezer, Yahoo Mail)"
"$SCRIPT_DIR/install-deezer-webapp.sh"
"$SCRIPT_DIR/install-yahoo-mail-webapp.sh"

echo "  -> Mullvad Browser policies (unified extensions)"
"$SCRIPT_DIR/setup-mullvad-policies.sh" ||
  printf '%s\n' "  Note: rerun setup-mullvad-policies.sh to install extension policies." >&2

echo "  -> Mullvad profile configs (Perso, Easier, WebApps)"
"$SCRIPT_DIR/setup-mullvad-profiles.sh" || true

# ---------------------------------------------------------------------------
# 4) Optional cleanup
# ---------------------------------------------------------------------------

echo "==> [4/4] Optional cleanup"
echo "  -> Remove undesired chat/media packages (signal, spotify, 1password)"
"$SCRIPT_DIR/remove-chat-and-media-apps.sh"

echo
echo "Master installation finished."
echo
echo "Optional manual step (edits /boot/limine.conf — run when ready):"
echo "  ${SCRIPT_DIR}/setup-limine-quiet-boot.sh"
