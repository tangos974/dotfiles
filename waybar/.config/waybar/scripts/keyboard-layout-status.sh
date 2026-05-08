#!/usr/bin/env bash
# Print the active xkb layout (GB / US / FR) for the Waybar indicator.
#
# Source of truth is Hyprland (xkb), not fcitx5: per fcitx-im.org/wiki the
# fcitx5 "managed layout" feature does not work on Hyprland — fcitx5 only
# pushes layouts to KDE Plasma and GNOME. So we read the first non-virtual
# keyboard's active_layout_index and map it via the `layout` CSV.

set -euo pipefail

hyprctl devices -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
kbs = [k for k in data.get("keyboards", []) if "virtual" not in k.get("name", "").lower()]
if not kbs:
    print("?"); sys.exit(0)
kb = kbs[0]
layouts = [s.strip() for s in kb.get("layout", "").split(",") if s.strip()]
idx = kb.get("active_layout_index", 0)
code = layouts[idx] if 0 <= idx < len(layouts) else "?"
print(code.upper())
'
