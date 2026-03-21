#!/bin/sh
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
HYPR_PKG_DIR="${DOTFILES_DIR}/hypr/.config/hypr"
UWSM_PKG_DIR="${DOTFILES_DIR}/uwsm/.config/uwsm"

LIVE_HYPR_DIR="${HOME}/.config/hypr"
LIVE_UWSM_DIR="${HOME}/.config/uwsm"

LIVE_BINDINGS="${LIVE_HYPR_DIR}/bindings.conf"
LIVE_UWSM_DEFAULT="${LIVE_UWSM_DIR}/default"

REPO_BINDINGS="${HYPR_PKG_DIR}/bindings.conf"
REPO_UWSM_DEFAULT="${UWSM_PKG_DIR}/default"

OMARCHY_BIN_REPO_DIR="${DOTFILES_DIR}/omarchy-bin/.local/share/omarchy/bin"
LIVE_OMARCHY_BIN_DIR="${HOME}/.local/share/omarchy/bin"

LIVE_OMARCHY_WEBAPP="${LIVE_OMARCHY_BIN_DIR}/omarchy-launch-webapp"
LIVE_OMARCHY_FOCUS_WEBAPP="${LIVE_OMARCHY_BIN_DIR}/omarchy-launch-or-focus-webapp"

REPO_OMARCHY_WEBAPP="${OMARCHY_BIN_REPO_DIR}/omarchy-launch-webapp"
REPO_OMARCHY_FOCUS_WEBAPP="${OMARCHY_BIN_REPO_DIR}/omarchy-launch-or-focus-webapp"

backup_if_needed() {
  path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    dest="${path}.before-stow"
    if [ -e "$dest" ]; then
      dest="${path}.before-stow.$(date +%s)"
    fi
    mv "$path" "$dest"
  fi
}

ensure_parent_dirs() {
  mkdir -p "$HYPR_PKG_DIR" "$UWSM_PKG_DIR" "$LIVE_HYPR_DIR" "$LIVE_UWSM_DIR" "$OMARCHY_BIN_REPO_DIR" "$LIVE_OMARCHY_BIN_DIR"
}

copy_live_to_repo_if_missing() {
  live="$1"
  repo="$2"

  if [ ! -e "$repo" ]; then
    if [ -e "$live" ]; then
      cp -a "$live" "$repo"
    else
      touch "$repo"
    fi
  fi
}

install_browser() {
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm mullvad-browser-bin
  else
    echo "yay not found. Install yay first, or install mullvad-browser-bin manually."
    exit 1
  fi
}

set_default_browser() {
  # Often fails when uwsm/session sets $BROWSER; we still set it in ~/.config/uwsm/default below.
  xdg-settings set default-web-browser mullvad-browser.desktop || true

  if grep -q '^export BROWSER=' "$REPO_UWSM_DEFAULT" 2>/dev/null; then
    sed -i 's|^export BROWSER=.*$|export BROWSER=mullvad-browser|g' "$REPO_UWSM_DEFAULT"
  else
    printf '\nexport BROWSER=mullvad-browser\n' >> "$REPO_UWSM_DEFAULT"
  fi
}

update_bindings_conf() {
  # Replace the Omarchy browser launcher variable if present.
  if grep -q '^\$browser = ' "$REPO_BINDINGS"; then
    sed -i 's|^\$browser = .*$|$browser = uwsm app -- mullvad-browser --new-window|g' "$REPO_BINDINGS"
  else
    printf '\n$browser = uwsm app -- mullvad-browser --new-window\n' >> "$REPO_BINDINGS"
  fi

  # Optional: keep webapps wired to the browser command if the variable exists.
  if ! grep -q '^\$webapp = ' "$REPO_BINDINGS"; then
    printf '$webapp = $browser --app\n' >> "$REPO_BINDINGS"
  fi

  # Remove default browser bind on SUPER+SHIFT+B if present.
  sed -i '/bindd = SUPER SHIFT, B, Browser, exec, omarchy-launch-browser/d' "$REPO_BINDINGS"
  sed -i '/bind = SUPER SHIFT, B, exec, omarchy-launch-browser/d' "$REPO_BINDINGS"

  # Remove our custom bind first if already present, then add it once.
  sed -i '/bindd = SUPER SHIFT, RETURN, Browser, exec, omarchy-launch-browser/d' "$REPO_BINDINGS"
  sed -i '/bind = SUPER SHIFT, RETURN, exec, omarchy-launch-browser/d' "$REPO_BINDINGS"

  # Re-add BOTH browser binds, now targeting Mullvad through Omarchy's browser launcher.
  printf '\nbindd = SUPER SHIFT, B, Browser, exec, omarchy-launch-browser\n' >> "$REPO_BINDINGS"
  printf 'bindd = SUPER SHIFT, RETURN, Browser, exec, omarchy-launch-browser\n' >> "$REPO_BINDINGS"
}

stow_configs() {
  . "$SCRIPT_DIR/dotfiles-stow.sh"
  stow_pkg hypr
  stow_pkg uwsm
  stow_pkg omarchy-bin
}

main() {
  ensure_parent_dirs

  copy_live_to_repo_if_missing "$LIVE_BINDINGS" "$REPO_BINDINGS"
  copy_live_to_repo_if_missing "$LIVE_UWSM_DEFAULT" "$REPO_UWSM_DEFAULT"

  backup_if_needed "$LIVE_BINDINGS"
  backup_if_needed "$LIVE_UWSM_DEFAULT"

  install_browser
  set_default_browser
  update_bindings_conf
  stow_configs

  hyprctl reload || true

  echo
  echo "Done."
  echo "Default browser set to Mullvad Browser."
  echo "Browser hotkey remapped to SUPER + SHIFT + ENTER."
  echo "Backups, if created:"
  echo "  $LIVE_BINDINGS.before-stow"
  echo "  $LIVE_UWSM_DEFAULT.before-stow"
}

main "$@"
