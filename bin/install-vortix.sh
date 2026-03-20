#!/bin/sh
set -eu

# Vortix / WireGuard setup for Arch
# Clean DNS stack:
#   - systemd-resolved
#   - systemd-resolvconf (compat resolvconf for wg-quick DNS=)

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

pkg_install() {
  if need_cmd yay; then
    yay -S --needed --noconfirm "$@"
  elif need_cmd pacman; then
    sudo pacman -S --needed --noconfirm "$@"
  else
    printf '%s\n' "Need yay or pacman." >&2
    exit 1
  fi
}

cleanup_old_hacks() {
  sudo systemctl disable --now resolvconf-sync.path 2>/dev/null || true
  sudo rm -f /etc/systemd/system/resolvconf-sync.path
  sudo rm -f /etc/systemd/system/resolvconf-sync.service
  sudo rm -f /usr/local/bin/resolvconf-path-sync.sh
  sudo rm -f /etc/systemd/system/systemd-resolved.service.d/99-resolvconf-sync.conf
  sudo rmdir /etc/systemd/system/systemd-resolved.service.d 2>/dev/null || true
}

configure_resolved() {
  sudo systemctl enable --now systemd-resolved

  # Backup existing resolv.conf once
  if [ -e /etc/resolv.conf ] && [ ! -L /etc/resolv.conf ] && [ ! -e /etc/resolv.conf.vortix-bak ]; then
    sudo cp -a /etc/resolv.conf /etc/resolv.conf.vortix-bak
  fi

  # Recommended stub symlink for systemd-resolved
  sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}

main() {

  pkg_install vortix wireguard-tools systemd-resolvconf openvpn

  cleanup_old_hacks
  sudo systemctl daemon-reload
  configure_resolved

  printf '\n%s\n' "Done."
  printf '%s\n' "Installed: vortix, wireguard-tools, systemd-resolvconf, openvpn"
  printf '%s\n' "Enabled: systemd-resolved"
  printf '%s\n' "Set: /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf"

  printf '\n%s\n' "Sanity checks:"
  printf '  %s\n' "ls -l /etc/resolv.conf"
  printf '  %s\n' "resolvectl status"
  printf '  %s\n' "sudo wg-quick up ~/.config/vortix/profiles/Homelab.conf"
}

main "$@"