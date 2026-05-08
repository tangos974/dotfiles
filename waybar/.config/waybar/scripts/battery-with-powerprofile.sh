#!/bin/bash
# Waybar custom module: same battery glyph and tooltip as the stock module,
# with a power-profile bar segment drawn in front of the icon.
#
#   power-saver  -> ▁  (low)
#   balanced     -> ▄  (middle)
#   performance  -> ▇  (high)
#
# Mirrors the bar-on-icon pattern used by the RAM/disk modules.

set -u

battery_dir() {
  for d in /sys/class/power_supply/BAT*; do
    [ -d "$d" ] && { printf '%s\n' "$d"; return 0; }
  done
  return 1
}

ac_online() {
  for f in /sys/class/power_supply/AC*/online \
           /sys/class/power_supply/ACAD/online \
           /sys/class/power_supply/ADP*/online; do
    [ -f "$f" ] && { cat "$f" 2>/dev/null; return; }
  done
  echo 0
}

BAT=$(battery_dir) || { printf '{"text":"","tooltip":"No battery"}\n'; exit 0; }

CAP=$(cat "$BAT/capacity" 2>/dev/null || echo 0)
STATUS=$(cat "$BAT/status" 2>/dev/null || echo Unknown)
AC=$(ac_online | head -1)

# Same icon arrays the stock battery module used.
charging_icons=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
default_icons=( "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
full_icon="󰂅"
# format-plugged glyph (fontawesome plug U+F1E6) — keep verbatim from old config.
printf -v plugged_icon '\xef\x87\xa6'

idx=$(( CAP / 10 ))
[ "$idx" -gt 9 ] && idx=9
[ "$idx" -lt 0 ] && idx=0

if [ "$STATUS" = "Full" ] || [ "$CAP" -ge 100 ]; then
  bat_icon="$full_icon"
elif [ "$STATUS" = "Charging" ]; then
  bat_icon="${charging_icons[$idx]}"
elif [ "$AC" = "1" ] && [ "$STATUS" != "Discharging" ]; then
  bat_icon="$plugged_icon"
else
  bat_icon="${default_icons[$idx]}"
fi

PROFILE=$(powerprofilesctl get 2>/dev/null || echo balanced)
case "$PROFILE" in
  performance) prof_icon="󰓅"; class="performance" ;;
  power-saver) prof_icon="󰌪"; class="power-saver" ;;
  balanced|*)  prof_icon="󰊚"; class="balanced"    ;;
esac

# Warning/critical class so any existing CSS keeps working.
state_class=""
if [ "$STATUS" = "Discharging" ]; then
  if   [ "$CAP" -le 10 ]; then state_class=" critical"
  elif [ "$CAP" -le 20 ]; then state_class=" warning"
  fi
fi

text="${bat_icon}<span size='8000' rise='-1000'>${prof_icon}</span>"

# Tooltip identical to the stock module: "{power:>1.0f}W{arrow} {capacity}%"
arrow="↓"; [ "$STATUS" = "Charging" ] && arrow="↑"

# Try power_now first; if missing or zero, calculate from current_now × voltage_now
uw=0
if [ -f "$BAT/power_now" ]; then
  uw=$(cat "$BAT/power_now" 2>/dev/null || echo 0)
fi
if [ "$uw" -eq 0 ] 2>/dev/null && [ -f "$BAT/current_now" ] && [ -f "$BAT/voltage_now" ]; then
  ua=$(cat "$BAT/current_now" 2>/dev/null || echo 0)
  uv=$(cat "$BAT/voltage_now" 2>/dev/null || echo 0)
  uw=$(awk -v i="$ua" -v v="$uv" 'BEGIN { printf "%.0f", i * v / 1000000 }')
fi
w=$(awk -v v="$uw" 'BEGIN { printf "%.0f", v/1000000 }')
tooltip="${w}W${arrow} ${CAP}%"

jq -cn \
  --arg text "$text" \
  --arg tooltip "$tooltip" \
  --arg class "${class}${state_class}" \
  --arg alt "$PROFILE" \
  '{text: $text, tooltip: $tooltip, class: $class, alt: $alt}'
