#!/usr/bin/env bash

set -euo pipefail

GHOSTTY_CONFIG="${HOME}/.config/ghostty/config"
SERVICE_NAME="app-com.mitchellh.ghostty.service"
SERVICE_OVERRIDE_DIR="${HOME}/.config/systemd/user/${SERVICE_NAME}.d"
SERVICE_OVERRIDE_FILE="${SERVICE_OVERRIDE_DIR}/override.conf"

mkdir -p "${HOME}/.config/ghostty"
touch "$GHOSTTY_CONFIG"

if grep -q '^quit-after-last-window-closed' "$GHOSTTY_CONFIG"; then
  sed -i 's/^quit-after-last-window-closed.*/quit-after-last-window-closed = false/' "$GHOSTTY_CONFIG"
else
  printf '\n# Keep Ghostty preload instance alive after last window closes\nquit-after-last-window-closed = false\n' >> "$GHOSTTY_CONFIG"
fi

mkdir -p "$SERVICE_OVERRIDE_DIR"
cat >"$SERVICE_OVERRIDE_FILE" <<'EOF'
[Service]
# Ghostty can exit 0 before sd_notify handshake completes in some builds.
# Type=simple avoids false protocol failures while keeping preload behavior.
Type=simple
BusName=
EOF

systemctl --user daemon-reload
systemctl --user enable "$SERVICE_NAME"
systemctl --user restart "$SERVICE_NAME"

echo "Configured ${SERVICE_NAME} and updated ${GHOSTTY_CONFIG}."
systemctl --user is-enabled "$SERVICE_NAME"
systemctl --user is-active "$SERVICE_NAME"
