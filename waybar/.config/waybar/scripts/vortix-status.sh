#!/usr/bin/env python3
"""Waybar JSON for VPN status (WireGuard + Vortix OpenVPN run/*.pid)."""
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path


def wg_active() -> bool:
    try:
        r = subprocess.run(
            ["wg", "show", "interfaces"],
            capture_output=True,
            text=True,
            timeout=2,
        )
        return r.returncode == 0 and bool(r.stdout.strip())
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def vortix_openvpn_active() -> bool:
    run_dir = Path.home() / ".config" / "vortix" / "run"
    if not run_dir.is_dir():
        return False
    for pidf in run_dir.glob("*.pid"):
        try:
            pid = int(pidf.read_text().strip())
        except ValueError:
            continue
        try:
            os.kill(pid, 0)
        except OSError:
            continue
        return True
    return False


def main() -> None:
    wg = wg_active()
    ov = vortix_openvpn_active()

    if wg and ov:
        tip = "WireGuard + OpenVPN active"
    elif wg:
        tip = "WireGuard active"
    elif ov:
        tip = "OpenVPN active"
    else:
        tip = "VPN inactive"

    cls = "connected" if (wg or ov) else "disconnected"
    # Font Awesome lock (JetBrainsMono Nerd Font)
    icon = "\uf023"
    print(json.dumps({"text": icon, "tooltip": tip, "class": cls}, ensure_ascii=False))


if __name__ == "__main__":
    main()
