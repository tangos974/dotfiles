#!/bin/sh
# Set up the keyboard layout selector (Waybar indicator + gum TUI manager)
# routed through fcitx5.
#
# Why fcitx5: its virtual keyboard claims main:true in Hyprland and
# re-broadcasts its keymap on every focus change, clobbering any
# `hyprctl switchxkblayout`. Letting fcitx5 own the layout state avoids
# that fight, and fcitx5 stays responsible for ~/.XCompose (compose key
# emoji shortcuts and the user/email bindings).
#
# Files (all stowed by master-installation.sh; this script just reloads):
#   fcitx5/.config/fcitx5/profile                            (group: gb-intl, us, fr)
#   waybar/.config/waybar/scripts/keyboard-layout-status.sh  (oneshot indicator)
#   waybar/.config/waybar/scripts/keyboard-layout-menu.sh    (gum-based switch / add / remove)
#   waybar/.config/waybar/config.jsonc                       ("custom/keyboard-layout" module)

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

. "$SCRIPT_DIR/dotfiles-stow.sh"

stow_pkg fcitx5
stow_pkg hypr
stow_pkg waybar

WAYBAR_SCRIPTS="${DOTFILES_DIR}/waybar/.config/waybar/scripts"
chmod +x \
  "${WAYBAR_SCRIPTS}/keyboard-layout-status.sh" \
  "${WAYBAR_SCRIPTS}/keyboard-layout-menu.sh" 2>/dev/null || true

# python3-dbus is needed by the menu (parse fcitx5 group info via dbus).
if ! python3 -c "import dbus" 2>/dev/null; then
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm python-dbus
  fi
fi

# Restart fcitx5 so it re-reads the stowed profile.
command -v omarchy-restart-app >/dev/null 2>&1 \
  && omarchy-restart-app fcitx5 --disable notificationitem >/dev/null 2>&1 \
  || { pkill -x fcitx5 2>/dev/null || true; sleep 0.5; setsid -f fcitx5 --disable notificationitem >/dev/null 2>&1 < /dev/null; }

command -v omarchy-restart-waybar >/dev/null 2>&1 && omarchy-restart-waybar 2>/dev/null || true

echo "Done: keyboard layout selector via fcitx5 (GB / US / FR) — click the Waybar indicator to switch / add / remove."
