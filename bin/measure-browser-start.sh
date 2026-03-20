#!/bin/sh

MATCH_REGEX="${1:-Mullvad Browser|WebApp|mullvad-browser}"
shift || true

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
START_MS=$(date +%s%3N)
LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

timeout 20s socat -U "UNIX-CONNECT:$SOCK" - 2>/dev/null \
  | stdbuf -oL tee "$LOG" \
  | stdbuf -oL awk -v start="$START_MS" -v re="$MATCH_REGEX" '
      /^(openwindow|activewindow)>>/ {
        print
        if ($0 ~ re) {
          cmd="date +%s%3N"
          cmd | getline now
          close(cmd)
          printf("MATCH after %d ms\n", now - start)
          exit 0
        }
      }
    ' &
WATCH_PID=$!

sleep 0.15
"$@" >/dev/null 2>&1 &

if wait "$WATCH_PID"; then
  exit 0
else
  echo
  echo "No matching event within timeout."
  echo "Seen events:"
  sed -n '/^\(openwindow\|activewindow\)>>/p' "$LOG" | tail -n 20
  exit 1
fi