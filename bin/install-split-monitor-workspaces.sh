#!/usr/bin/env bash
set -euo pipefail

PLUGIN_REPO="https://github.com/zjeffer/split-monitor-workspaces"
PLUGIN_NAME="split-monitor-workspaces"

if ! command -v hyprpm >/dev/null 2>&1; then
  echo "hyprpm not found. Make sure Hyprland/Omarchy is installed correctly."
  exit 1
fi

echo "Adding plugin repository..."
hyprpm add "${PLUGIN_REPO}" || true

echo "Enabling plugin..."
hyprpm enable "${PLUGIN_NAME}"

echo "Reloading plugins..."
hyprpm reload

echo
echo "Done."
echo "If this was the first install, also make sure your Hypr config sources split-monitor-workspaces.conf"

