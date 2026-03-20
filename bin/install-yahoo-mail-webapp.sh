#!/usr/bin/env sh

set -eu

DOTFILES_DIR="${HOME}/dotfiles"
REPO_BINDINGS="${DOTFILES_DIR}/hypr/.config/hypr/bindings.conf"
LIVE_BINDINGS="${HOME}/.config/hypr/bindings.conf"
MAIL_URL="https://mail.yahoo.com/"
MAIL_BIND="bindd = SUPER SHIFT, E, Email, exec, omarchy-launch-webapp \"${MAIL_URL}\""
ICON_DIR="${HOME}/.local/share/applications/icons"
MAIL_ICON="${ICON_DIR}/Yahoo Mail.png"

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

update_email_binding() {
  sed -i '/^bindd = SUPER SHIFT, E, /d' "$REPO_BINDINGS"
  sed -i '/^bind = SUPER SHIFT, E, /d' "$REPO_BINDINGS"
  printf '\n%s\n' "$MAIL_BIND" >> "$REPO_BINDINGS"
}

install_yahoo_mail_launcher() {
  mkdir -p "$ICON_DIR"

  if ! curl -fsSL -A "Mozilla/5.0" -o "$MAIL_ICON" "https://mail.yahoo.com/favicon.ico"; then
    for source in \
      "${ICON_DIR}/ChatGPT.png" \
      "/usr/share/icons/hicolor/128x128/apps/firefox.png" \
      "/usr/share/icons/hicolor/128x128/apps/chromium.png"; do
      if [ -s "$source" ]; then
        cp -f "$source" "$MAIL_ICON"
        break
      fi
    done
  fi

  omarchy-webapp-install \
    "Yahoo Mail" \
    "$MAIL_URL" \
    "Yahoo Mail.png"
}

apply_and_reload() {
  backup_if_needed "$LIVE_BINDINGS"
  cd "$DOTFILES_DIR"
  stow -v -t ~ hypr
  hyprctl reload >/dev/null 2>&1 || true
}

main() {
  install_yahoo_mail_launcher
  ensure_repo_bindings_exists
  update_email_binding
  apply_and_reload

  echo "Done."
  echo "SUPER+SHIFT+E now launches Yahoo Mail."
  echo "Launcher: Yahoo Mail (Super+Space)."
}

main "$@"
