#!/bin/sh

SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
LOG="/tmp/watch-monitor-events.log"

echo "starting watcher at $(date)" >> "$LOG"
echo "socket: $SOCK" >> "$LOG"

socat -U - UNIX-CONNECT:"$SOCK" | while IFS= read -r line; do
  echo "$(date) :: $line" >> "$LOG"
  case "$line" in
    monitoradded*|monitorremoved*)
      echo "$(date) :: rerunning adapt-workspaces" >> "$LOG"
      "$HOME/.local/bin/adapt-workspaces.sh" >> "$LOG" 2>&1
      pkill -x waybar >/dev/null 2>&1 || true
      sleep 0.2
      # Restart through uwsm-app so the new waybar inherits the systemd user
      # manager's env (incl. omarchy-overrides on PATH). Plain `nohup waybar &`
      # clones this script's frozen env and re-breaks waybar on-click TUIs.
      setsid uwsm-app -- waybar >/tmp/waybar.log 2>&1 &
      ;;
  esac
done
