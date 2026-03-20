#!/bin/sh

PROFILE_NAME="WebApps"
DOTFILES_DIR="${HOME}/dotfiles"
TEMPLATE_DIR="${DOTFILES_DIR}/mullvad-webapp/.config/mullvad-webapp"

backup_if_needed() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ] && [ ! -e "${path}.before-stow" ]; then
    mv "$path" "${path}.before-stow"
  fi
}

find_profiles_ini() {
  find "$HOME" -maxdepth 4 -type f -name profiles.ini 2>/dev/null
}

find_profile_dir_from_ini() {
  local ini="$1"

  python3 - "$ini" "$PROFILE_NAME" <<'PY'
import configparser
import os
import sys

ini = sys.argv[1]
target = sys.argv[2]

cp = configparser.RawConfigParser()
cp.read(ini)

base = os.path.dirname(ini)

for section in cp.sections():
    if not section.startswith("Profile"):
        continue
    name = cp.get(section, "Name", fallback="")
    if name != target:
        continue

    rel = cp.get(section, "IsRelative", fallback="1")
    path = cp.get(section, "Path", fallback="")
    if not path:
        continue

    if rel == "1":
        print(os.path.normpath(os.path.join(base, path)))
    else:
        print(os.path.normpath(path))
    sys.exit(0)

sys.exit(1)
PY
}

ensure_profile_exists() {
  # Try the direct command first.
  mullvad-browser -CreateProfile "${PROFILE_NAME}" >/dev/null 2>&1 || true

  # If the wrapper didn't create it, user can still do it once manually with:
  # mullvad-browser -P
}

discover_profile_dir() {
  local ini
  while IFS= read -r ini; do
    if dir="$(find_profile_dir_from_ini "$ini" 2>/dev/null)"; then
      if [ -n "${dir:-}" ] && [ -d "$dir" ]; then
        printf '%s\n' "$dir"
        return 0
      fi
    fi
  done < <(find_profiles_ini)

  return 1
}

main() {
  if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Template directory missing: $TEMPLATE_DIR" >&2
    exit 1
  fi

  ensure_profile_exists

  PROFILE_DIR="$(discover_profile_dir || true)"
  if [ -z "${PROFILE_DIR:-}" ]; then
    echo "Could not discover the Mullvad WebApps profile automatically." >&2
    echo "Open mullvad-browser, visit about:profiles, create/select the '${PROFILE_NAME}' profile once, then rerun this script." >&2
    exit 1
  fi

  mkdir -p "$PROFILE_DIR/chrome"

  backup_if_needed "$PROFILE_DIR/user.js"
  backup_if_needed "$PROFILE_DIR/chrome/userChrome.css"

  ln -sfn "$TEMPLATE_DIR/user.js" "$PROFILE_DIR/user.js"
  ln -sfn "$TEMPLATE_DIR/userChrome.css" "$PROFILE_DIR/chrome/userChrome.css"

  echo "Linked:"
  echo "  $PROFILE_DIR/user.js -> $TEMPLATE_DIR/user.js"
  echo "  $PROFILE_DIR/chrome/userChrome.css -> $TEMPLATE_DIR/userChrome.css"
}

main "$@"
