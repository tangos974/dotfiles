#!/bin/bash
# Toggle always-on (no-sleep) mode - bound to the eye icon in waybar.
set -u

UNIT=always-on.service

if systemctl --user is-active --quiet "$UNIT"; then
  systemctl --user stop "$UNIT"
  notify-send -u low "$(printf '\U000F0209')  Normal sleep mode" \
    "Screensaver, lock, suspend and lid-close are active again."
elif systemctl --user start "$UNIT"; then
  notify-send -u low "$(printf '\U000F0208')  Always-on mode" \
    "No sleep, no lock, no screen blanking. Lid close is ignored."
else
  notify-send -u critical "Always-on mode failed" \
    "Could not start $UNIT - see: systemctl --user status $UNIT"
fi

pkill -RTMIN+12 waybar
