#!/bin/sh
# Fix: resolvconf: signature mismatch: /etc/resolv.conf (openresolv vs systemd-resolved stub).
# Run before connecting WireGuard/Vortix if VPN keeps tearing down at the resolvconf step.
set -e
sudo resolvconf -u
