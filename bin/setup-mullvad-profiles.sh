#!/bin/sh

# Setup Mullvad Browser profiles deterministically from dotfiles.
#
# The profile definitions (names + paths) live in mullvad-profiles/profiles.ini
# and are installed as a copy (not a symlink) — the browser rewrites profiles.ini
# on first launch (adds an [InstallXXXX] section with a machine-specific hash),
# so a stow symlink would pull that churn into the repo.
#
# On first run after a non-deterministic install, existing random-prefix
# profile dirs (e.g. f8k4n14q.default-release) are renamed to the deterministic
# names (Perso / Easier / WebApps) — browsing data is preserved.

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=dotfiles-stow.sh
. "${SCRIPT_DIR}/dotfiles-stow.sh"

MULLVAD_DIR="${HOME}/.mullvad/mullvadbrowser"
PROFILES_INI="${MULLVAD_DIR}/profiles.ini"
INSTALLS_INI="${MULLVAD_DIR}/installs.ini"
DOTFILES_PROFILES_INI="${DOTFILES_DIR}/mullvad-profiles/profiles.ini"

# Profile name -> (stow package, .config subdir) holding user.js + userChrome.css
PROFILE_MAP="
Perso:mullvad-perso:mullvad-perso
Easier:mullvad-easier:mullvad-easier
WebApps:mullvad-webapp:mullvad-webapp
"

abort_if_browser_running() {
  # comm is truncated to 15 chars (mullvadbrowser.), so match the full path with -f.
  if pgrep -f '/mullvadbrowser\.real( |$)' >/dev/null 2>&1; then
    echo "Mullvad Browser is running. Quit it first, then re-run this script." >&2
    echo "  (renaming profile directories under a live browser leaves the" >&2
    echo "   browser pointing at stale path strings; new file opens may fail.)" >&2
    exit 1
  fi
}

# Read Path= for the given profile name from the existing profiles.ini.
# Prints absolute path to stdout (empty if not found / file missing).
existing_profile_path() {
  target_name="$1"
  [ -f "$PROFILES_INI" ] || return 0
  python3 - "$target_name" "$PROFILES_INI" <<'PY'
import configparser, os, sys
target, ini = sys.argv[1], sys.argv[2]
cp = configparser.RawConfigParser()
cp.read(ini)
for s in cp.sections():
    if not s.startswith("Profile"):
        continue
    if cp.get(s, "Name", fallback="") == target:
        path = cp.get(s, "Path", fallback="")
        if not path:
            sys.exit(0)
        if cp.get(s, "IsRelative", fallback="1") == "1":
            print(os.path.normpath(os.path.join(os.path.dirname(ini), path)))
        else:
            print(path)
        sys.exit(0)
PY
}

migrate_profile_dir() {
  target_name="$1"
  target_dir="${MULLVAD_DIR}/${target_name}"

  if [ -d "$target_dir" ]; then
    return 0
  fi

  old_path="$(existing_profile_path "$target_name")"
  if [ -n "$old_path" ] && [ -d "$old_path" ] && [ "$old_path" != "$target_dir" ]; then
    echo "  Migrating ${old_path} -> ${target_dir}"
    mv -- "$old_path" "$target_dir"
    return 0
  fi

  mkdir -p "$target_dir"
  echo "  Created empty profile dir: $target_dir"
}

install_profiles_ini() {
  if [ ! -f "$DOTFILES_PROFILES_INI" ]; then
    echo "Source profiles.ini not found: $DOTFILES_PROFILES_INI" >&2
    exit 1
  fi

  mkdir -p "$MULLVAD_DIR"

  if [ -f "$PROFILES_INI" ] && ! cmp -s "$PROFILES_INI" "$DOTFILES_PROFILES_INI"; then
    backup_if_needed "$PROFILES_INI"
  fi

  cp -- "$DOTFILES_PROFILES_INI" "$PROFILES_INI"
  echo "Installed profiles.ini -> $PROFILES_INI"

  # installs.ini pins the default profile by old (random) path. Drop it; the
  # browser regenerates it on next launch using profiles.ini's Default=1.
  if [ -f "$INSTALLS_INI" ]; then
    backup_if_needed "$INSTALLS_INI"
    rm -f -- "$INSTALLS_INI"
    echo "Removed stale installs.ini (browser will regenerate)"
  fi
}

link_profile_configs() {
  profile_name="$1"
  stow_pkg="$2"
  config_subdir="$3"

  template_dir="${DOTFILES_DIR}/${stow_pkg}/.config/${config_subdir}"
  profile_dir="${MULLVAD_DIR}/${profile_name}"

  if [ ! -d "$template_dir" ]; then
    echo "WARNING: Template directory missing: $template_dir" >&2
    return 1
  fi

  mkdir -p "$profile_dir/chrome"

  backup_if_needed "$profile_dir/user.js"
  backup_if_needed "$profile_dir/chrome/userChrome.css"

  ln -sfn "$template_dir/user.js" "$profile_dir/user.js"
  ln -sfn "$template_dir/userChrome.css" "$profile_dir/chrome/userChrome.css"

  echo "Linked $profile_name:"
  echo "  $profile_dir/user.js -> $template_dir/user.js"
  echo "  $profile_dir/chrome/userChrome.css -> $template_dir/userChrome.css"
}

main() {
  if ! command -v mullvad-browser >/dev/null 2>&1; then
    echo "mullvad-browser not found. Install Mullvad Browser first." >&2
    exit 1
  fi

  abort_if_browser_running

  echo "Migrating any random-prefix profile directories..."
  echo "$PROFILE_MAP" | while IFS=: read -r profile_name _ _; do
    [ -z "$profile_name" ] && continue
    migrate_profile_dir "$profile_name"
  done

  install_profiles_ini

  echo "$PROFILE_MAP" | while IFS=: read -r profile_name stow_pkg config_subdir; do
    [ -z "$profile_name" ] && continue
    link_profile_configs "$profile_name" "$stow_pkg" "$config_subdir"
  done

  echo ""
  echo "Done. Restart Mullvad Browser for changes to take effect."
}

main "$@"
