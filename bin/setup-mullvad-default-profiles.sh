#!/bin/sh

# Apply default styling (no content padding) to all Mullvad profiles except WebApps.

EXCLUDE_PROFILE="WebApps"
DOTFILES_DIR="${HOME}/dotfiles"
TEMPLATE_DIR="${DOTFILES_DIR}/mullvad-default/.config/mullvad-webapp"

backup_if_needed() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ] && [ ! -e "${path}.before-stow" ]; then
    mv "$path" "${path}.before-stow"
  fi
}

find_profiles_ini() {
  find "$HOME" -maxdepth 4 -type f -name profiles.ini 2>/dev/null
}

# Output one profile directory path per line for all profiles except EXCLUDE_PROFILE.
# Reads list of profiles.ini paths from the file given as second argument.
list_profile_dirs_except() {
  local exclude="$1"
  local inilist="$2"
  python3 - "$exclude" "$inilist" <<'PY'
import configparser
import os
import sys

exclude = sys.argv[1]
inilist_path = sys.argv[2] if len(sys.argv) > 2 else None
inidirs = []
if inilist_path and os.path.isfile(inilist_path):
    with open(inilist_path) as f:
        inidirs = [line.strip() for line in f if line.strip()]

for ini in inidirs:
    if not os.path.isfile(ini):
        continue
    base = os.path.dirname(ini)
    cp = configparser.RawConfigParser()
    try:
        cp.read(ini)
    except Exception:
        continue
    for section in cp.sections():
        if not section.startswith("Profile"):
            continue
        name = cp.get(section, "Name", fallback="")
        if name == exclude:
            continue
        path = cp.get(section, "Path", fallback="")
        if not path:
            continue
        rel = cp.get(section, "IsRelative", fallback="1")
        if rel == "1":
            full = os.path.normpath(os.path.join(base, path))
        else:
            full = os.path.normpath(path)
        if os.path.isdir(full):
            print(full)
PY
}

main() {
  if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Template directory missing: $TEMPLATE_DIR" >&2
    exit 1
  fi

  inilist="$(mktemp)"
  find_profiles_ini > "$inilist"
  PROFILE_DIRS="$(list_profile_dirs_except "$EXCLUDE_PROFILE" "$inilist")"
  rm -f "$inilist"
  if [ -z "$PROFILE_DIRS" ]; then
    echo "No Mullvad profiles found (excluding '${EXCLUDE_PROFILE}'). Create a profile in about:profiles and rerun." >&2
    exit 1
  fi

  for PROFILE_DIR in $PROFILE_DIRS; do
    mkdir -p "$PROFILE_DIR/chrome"
    backup_if_needed "$PROFILE_DIR/user.js"
    backup_if_needed "$PROFILE_DIR/chrome/userChrome.css"
    ln -sfn "$TEMPLATE_DIR/user.js" "$PROFILE_DIR/user.js"
    ln -sfn "$TEMPLATE_DIR/userChrome.css" "$PROFILE_DIR/chrome/userChrome.css"
    echo "Linked: $PROFILE_DIR"
  done
}

main "$@"
