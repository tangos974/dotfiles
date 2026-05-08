#!/usr/bin/env bash
# Gum-based picker that switches the Hyprland xkb layout among the three
# entries declared in ~/.config/hypr/input.conf (gb,us,fr / intl,,).
#
# We drive Hyprland directly (`hyprctl switchxkblayout all <i>`) because
# fcitx5 cannot manage layouts on Hyprland (see fcitx-im.org/wiki). We
# then mirror the choice to fcitx5 via `fcitx5-remote -s keyboard-XX`,
# purely so the IM label agrees with what's actually being typed — this
# does NOT affect keystrokes, only fcitx5's internal label.

set -euo pipefail

# Pull live (layout, active_layout_index) from Hyprland's first physical
# keyboard. We pin items by xkb code rather than position so reordering
# kb_layout in input.conf doesn't silently miswire the menu.
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

label_for() {
  case "$1" in
    gb) echo "GB (intl)" ;;
    us) echo "US" ;;
    fr) echo "FR (azerty)" ;;
    *)  echo "${1^^}" ;;
  esac
}

fcitx_im_for() {
  case "$1" in
    gb) echo "keyboard-gb-intl" ;;
    us) echo "keyboard-us" ;;
    fr) echo "keyboard-fr" ;;
    *)  echo "keyboard-$1" ;;
  esac
}

options=()
for code in "${LAYOUTS[@]}"; do
  code="${code// /}"
  [[ -z "$code" ]] && continue
  marker="  "
  if [[ "$code" == "${LAYOUTS[$ACTIVE_IDX]// /}" ]]; then
    marker="* "
  fi
  options+=("${marker}$(label_for "$code") [${code}]")
done

if ! command -v gum >/dev/null 2>&1; then
  echo "gum is not installed" >&2
  exit 1
fi

choice=$(printf '%s\n' "${options[@]}" | gum choose --header "Keyboard layout" --height 8) || exit 0

# Extract bracketed code, e.g. "[gb]" -> gb
selected_code="${choice##*[}"
selected_code="${selected_code%]*}"

# Find its index in LAYOUTS.
new_idx=-1
for i in "${!LAYOUTS[@]}"; do
  if [[ "${LAYOUTS[$i]// /}" == "$selected_code" ]]; then
    new_idx=$i
    break
  fi
done
[[ "$new_idx" -lt 0 ]] && exit 0

hyprctl switchxkblayout all "$new_idx" >/dev/null

if command -v fcitx5-remote >/dev/null 2>&1; then
  fcitx5-remote -s "$(fcitx_im_for "$selected_code")" >/dev/null 2>&1 || true
fi

# Refresh the waybar indicator immediately (signal 13, see config.jsonc).
pkill -RTMIN+13 waybar 2>/dev/null || true
