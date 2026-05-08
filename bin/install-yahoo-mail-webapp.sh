#!/usr/bin/env sh
# Install the Yahoo Mail webapp launcher (icon + omarchy-webapp-install entry).
# The Hypr binding (SUPER+SHIFT+E -> Yahoo Mail) is committed in hypr/bindings.conf —
# it is NOT modified by this script.

set -eu

MAIL_URL="https://mail.yahoo.com/"
ICON_DIR="${HOME}/.local/share/applications/icons"
MAIL_ICON="${ICON_DIR}/Yahoo Mail.png"

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

echo "Done."
echo "  Launcher: Yahoo Mail (Super+Space)."
echo "  Binding:  SUPER+SHIFT+E (committed in hypr/bindings.conf)."
