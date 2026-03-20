#!/usr/bin/env python3
"""JSON for Waybar custom/memory-swap: percentage selects {icon} tier."""
import json
from pathlib import Path


def kb(prefix: str) -> int:
    for line in Path("/proc/meminfo").read_text().splitlines():
        if line.startswith(prefix):
            return int(line.split()[1])
    return 0


def gib(k: int) -> str:
    return f"{k / 1024 / 1024:.2f}"


st = kb("SwapTotal:")
sf = kb("SwapFree:")

swap_used = max(0, st - sf)
pct = int(swap_used * 100 / st) if st else 0
pct = max(0, min(100, pct))

if st:
    tooltip = f"Swap {gib(swap_used)} / {gib(st)} GiB ({pct}%)"
else:
    tooltip = "No swap"

cls = "ok"
if st and pct >= 80:
    cls = "critical"
elif st and pct >= 40:
    cls = "warning"
elif st == 0:
    cls = "noswap"

print(json.dumps({"percentage": pct, "tooltip": tooltip, "class": cls}))
