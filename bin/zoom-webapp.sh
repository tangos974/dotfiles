#!/bin/bash
# Launch Zoom Web client in Brave as a standalone app window.
# Accepts an optional zoommtg:// or zoomus:// URL and converts it to the
# corresponding https://app.zoom.us/wc/join/... URL.

set -euo pipefail

url="${1:-}"
web_url="https://app.zoom.us/wc/home"

if [[ "$url" =~ ^zoom(mtg|us):// ]]; then
  confno=$(echo "$url" | sed -n 's/.*[?&]confno=\([^&]*\).*/\1/p')
  if [[ -n "$confno" ]]; then
    pwd=$(echo "$url" | sed -n 's/.*[?&]pwd=\([^&]*\).*/\1/p')
    if [[ -n "$pwd" ]]; then
      web_url="https://app.zoom.us/wc/$confno/join?pwd=$pwd"
    else
      web_url="https://app.zoom.us/wc/$confno/join"
    fi
  fi
fi

exec setsid uwsm app -- brave \
  --app="$web_url" \
  --class=WebApp-Zoom \
  --user-data-dir="$HOME/.config/brave-webapps/zoom"
