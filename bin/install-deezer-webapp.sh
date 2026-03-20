#!/usr/bin/env sh

set -eu

DOTFILES_DIR="${HOME}/dotfiles"
REPO_BINDINGS="${DOTFILES_DIR}/hypr/.config/hypr/bindings.conf"
LIVE_BINDINGS="${HOME}/.config/hypr/bindings.conf"
DEEZER_BIND='bindd = SUPER SHIFT, M, Music, exec, omarchy-launch-webapp "https://www.deezer.com/"'
ICON_DIR="${HOME}/.local/share/applications/icons"
DEEZER_ICON="${ICON_DIR}/Deezer.png"

backup_if_needed() {
  path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ] && [ ! -e "${path}.before-stow" ]; then
    mv "$path" "${path}.before-stow"
  fi
}

ensure_repo_bindings_exists() {
  mkdir -p "$(dirname "$REPO_BINDINGS")"

  if [ ! -e "$REPO_BINDINGS" ]; then
    if [ -e "$LIVE_BINDINGS" ]; then
      cp -a "$LIVE_BINDINGS" "$REPO_BINDINGS"
    else
      : > "$REPO_BINDINGS"
    fi
  fi
}

update_music_binding() {
  # Remove current M binding(s), then add Deezer once.
  sed -i '/^bindd = SUPER SHIFT, M, /d' "$REPO_BINDINGS"
  sed -i '/^bind = SUPER SHIFT, M, /d' "$REPO_BINDINGS"
  printf '\n%s\n' "$DEEZER_BIND" >> "$REPO_BINDINGS"
}

install_deezer_launcher() {
  mkdir -p "$ICON_DIR"

  if ! curl -fsSL -A "Mozilla/5.0" -o "$DEEZER_ICON" "https://www.deezer.com/favicon.ico"; then
    for source in \
      "${ICON_DIR}/YouTube.png" \
      "${ICON_DIR}/ChatGPT.png" \
      "/usr/share/icons/hicolor/128x128/apps/firefox.png" \
      "/usr/share/icons/hicolor/128x128/apps/chromium.png"; do
      if [ -s "$source" ]; then
        cp -f "$source" "$DEEZER_ICON"
        break
      fi
    done
  fi

  omarchy-webapp-install \
    "Deezer" \
    "https://www.deezer.com/" \
    "Deezer.png"
}

apply_and_reload() {
  backup_if_needed "$LIVE_BINDINGS"
  cd "$DOTFILES_DIR"
  stow -v -t ~ hypr
  hyprctl reload >/dev/null 2>&1 || true
}

main() {
  install_deezer_launcher
  ensure_repo_bindings_exists
  update_music_binding
  apply_and_reload

  echo "Done."
  echo "SUPER+SHIFT+M now launches Deezer webapp."
}

main "$@"

