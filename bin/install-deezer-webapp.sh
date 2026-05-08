#!/usr/bin/env sh
# Install the Deezer webapp launcher (icon + omarchy-webapp-install entry).
# The Hypr binding (SUPER+SHIFT+M -> Deezer) is committed in hypr/bindings.conf —
# it is NOT modified by this script.

set -eu

ICON_DIR="${HOME}/.local/share/applications/icons"
DEEZER_ICON="${ICON_DIR}/Deezer.png"

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

echo "Done."
echo "  Launcher: Deezer (Super+Space)."
echo "  Binding:  SUPER+SHIFT+M (committed in hypr/bindings.conf)."
