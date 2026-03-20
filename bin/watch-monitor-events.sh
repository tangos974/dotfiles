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
      "$HOME/adapt-workspaces.sh" >> "$LOG" 2>&1
      pkill -x waybar >/dev/null 2>&1 || true
      sleep 0.2
      nohup waybar >/tmp/waybar.log 2>&1 &
      ;;
  esac
done
