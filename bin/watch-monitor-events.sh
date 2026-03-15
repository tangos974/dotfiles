#!/usr/bin/env bash
set -euo pipefail

SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

socat -U - UNIX-CONNECT:"$SOCK" | while IFS= read -r line; do
  case "$line" in
    monitoradded*|monitorremoved*)
      "$HOME/adapt-workspaces.sh"
      ;;
  esac
done
