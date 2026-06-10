#!/usr/bin/env bash
# Cycle to the next xkb layout. Same source of truth and side-effects as
# keyboard-layout-menu.sh — Hyprland xkb is authoritative; fcitx5 IM label
# is mirrored for display consistency; waybar is signalled to refresh.
#
# Intended to be bound to CTRL+SPACE in Hyprland so that key matches
# what the waybar selector does. See bindings.conf.

set -euo pipefail

read -r LAYOUT_CSV ACTIVE_IDX < <(
  hyprctl devices -j | python3 -c '
import json, sys
d = json.load(sys.stdin)
kbs = [k for k in d.get("keyboards", []) if "virtual" not in k.get("name", "").lower()]
kb = kbs[0] if kbs else {"layout": "", "active_layout_index": 0}
print(kb.get("layout", ""), kb.get("active_layout_index", 0))
'
)

IFS=',' read -r -a LAYOUTS <<<"$LAYOUT_CSV"
count="${#LAYOUTS[@]}"
[[ "$count" -lt 2 ]] && exit 0

next_idx=$(( (ACTIVE_IDX + 1) % count ))
next_code="${LAYOUTS[$next_idx]// /}"

hyprctl switchxkblayout all "$next_idx" >/dev/null

fcitx_im_for() {
  case "$1" in
    gb) echo "keyboard-gb-intl" ;;
    us) echo "keyboard-us" ;;
    fr) echo "keyboard-fr" ;;
    *)  echo "keyboard-$1" ;;
  esac
}

if command -v fcitx5-remote >/dev/null 2>&1; then
  fcitx5-remote -s "$(fcitx_im_for "$next_code")" >/dev/null 2>&1 || true
fi

pkill -RTMIN+13 waybar 2>/dev/null || true
