#!/usr/bin/env python3
"""JSON for Waybar custom/disk: % used on WAYBAR_DISK_PATH (default /) drives {icon} tiers."""
import json
import os
import shutil

path = os.environ.get("WAYBAR_DISK_PATH", "/")

try:
    du = shutil.disk_usage(path)
except OSError:
    print(
        json.dumps(
            {
                "percentage": 0,
                "tooltip": f"{path}\n(unreadable)",
                "class": "unreadable",
            }
        )
    )
    raise SystemExit(0)

pct = int(du.used * 100 / du.total) if du.total else 0
pct = max(0, min(100, pct))

used_gib = du.used / (1024**3)
total_gib = du.total / (1024**3)
free_gib = du.free / (1024**3)

tooltip = (
    f"{path}\n"
    f"{used_gib:.1f} / {total_gib:.1f} GiB used ({pct}%)\n"
    f"{free_gib:.1f} GiB free"
)

cls = "ok"
if pct >= 92:
    cls = "critical"
elif pct >= 82:
    cls = "warning"

print(json.dumps({"percentage": pct, "tooltip": tooltip, "class": cls}))
