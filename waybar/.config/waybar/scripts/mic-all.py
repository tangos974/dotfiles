#!/usr/bin/env python3
"""Mute/unmute all PipeWire capture sources (Audio/Source); Waybar JSON + toggle + OSD."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys

# Material Design icons (Nerd Fonts), same plane as voxtype 󰍬 — FA \uf130/\uf131 are empty in JetBrainsMono Nerd Font
ICON_MIC_ON = "\U000f036c"
ICON_MIC_OFF = "\U000f036d"


def _pactl_sources() -> list[dict]:
    r = subprocess.run(
        ["pactl", "-f", "json", "list", "sources"],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0:
        return []
    try:
        data = json.loads(r.stdout)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []


def capture_sources(sources: list[dict]) -> list[dict]:
    out: list[dict] = []
    for s in sources:
        props = s.get("properties") or {}
        name = s.get("name", "")
        desc = (s.get("description") or "").lower()

        if props.get("media.class") != "Audio/Source":
            continue
        if name.endswith(".monitor"):
            continue
        if "monitor of" in desc:
            continue
        if props.get("device.class") == "monitor":
            continue

        out.append(s)
    return out


def refresh_waybar(signal: int) -> None:
    subprocess.run(
        ["pkill", f"-SIGRTMIN+{signal}", "-x", "waybar"],
        capture_output=True,
    )


def show_osd(all_muted: bool) -> None:
    r = subprocess.run(
        ["hyprctl", "monitors", "-j"],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0:
        return
    try:
        monitors = json.loads(r.stdout)
    except json.JSONDecodeError:
        return
    name = None
    for m in monitors:
        if m.get("focused"):
            name = m.get("name")
            break
    if not name:
        return
    if all_muted:
        msg, icon = "Microphones muted", "microphone-sensitivity-muted"
    else:
        msg, icon = "Microphones on", "audio-input-microphone"
    subprocess.Popen(
        [
            "swayosd-client",
            "--monitor",
            name,
            "--custom-icon",
            icon,
            "--custom-message",
            msg,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def cmd_waybar() -> None:
    sources = capture_sources(_pactl_sources())
    if not sources:
        print(
            json.dumps(
                {
                    "text": ICON_MIC_OFF,
                    "tooltip": "No capture devices",
                    "class": "nomics",
                },
                ensure_ascii=False,
            )
        )
        return
    all_muted = all(s.get("mute") is True for s in sources)
    if all_muted:
        text, cls = ICON_MIC_OFF, "muted"
        tip = "All microphones muted (click to unmute)"
    else:
        text, cls = ICON_MIC_ON, "unmuted"
        names = ", ".join(s.get("description") or s.get("name", "?") for s in sources)
        tip = f"Microphones on: {names} (click to mute all)"
    print(json.dumps({"text": text, "tooltip": tip, "class": cls}, ensure_ascii=False))


def cmd_toggle(*, osd: bool, waybar_signal: int) -> None:
    sources = capture_sources(_pactl_sources())
    if not sources:
        if osd:
            show_osd(True)
        refresh_waybar(waybar_signal)
        return
    any_unmuted = any(s.get("mute") is not True for s in sources)
    new_mute = 1 if any_unmuted else 0
    for s in sources:
        subprocess.run(
            ["pactl", "set-source-mute", str(s["index"]), str(new_mute)],
            capture_output=True,
        )
    all_muted = bool(new_mute)
    if osd:
        show_osd(all_muted)
    refresh_waybar(waybar_signal)


def main() -> int:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("waybar", help="Print JSON for Waybar")
    t = sub.add_parser("toggle", help="Mute all if any live; else unmute all")
    t.add_argument(
        "--osd",
        action="store_true",
        help="Show SwayOSD notification (Hyprland focused monitor)",
    )
    t.add_argument(
        "--waybar-signal",
        type=int,
        default=11,
        help="Waybar SIGRTMIN+n to refresh mic module (default: 11)",
    )
    args = p.parse_args()
    if args.cmd == "waybar":
        cmd_waybar()
    else:
        cmd_toggle(osd=args.osd, waybar_signal=args.waybar_signal)
    return 0


if __name__ == "__main__":
    sys.exit(main())
