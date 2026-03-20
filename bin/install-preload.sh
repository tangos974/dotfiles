#!/usr/bin/env bash
#
# Install the preload AUR package (readahead daemon) and enable the system service.
# This is NOT Ghostty's app-com.mitchellh.ghostty.service — see setup-ghostty-preload.sh.

set -euo pipefail

install_pkg() {
  if command -v omarchy-pkg-aur-add >/dev/null 2>&1; then
    omarchy-pkg-aur-add preload
  elif command -v yay >/dev/null 2>&1; then
    yay -S --noconfirm --needed preload
  else
    echo "Need omarchy-pkg-aur-add or yay to install preload from the AUR." >&2
    exit 1
  fi
}

main() {
  install_pkg
  sudo systemctl enable --now preload.service

  echo
  echo "Done. preload.service is enabled and running."
  echo "Configs (package defaults; customize only if you need tuning):"
  echo "  /etc/preload.conf"
  echo "  /etc/conf.d/preload"
}

main "$@"
