#!/bin/sh
# Restore Plymouth-based pretty LUKS prompt on Omarchy.
# - Edits /etc/default/limine (persistent source)
# - Ensures kernel cmdline starts with: quiet splash
# - Removes the extra silent-boot flags and Plymouth-disable flags
# - Runs limine-update to regenerate /boot/limine.conf
#
# Usage: ./bin/setup-limine-restore-plymouth.sh
set -eu

LIMINE_DEFAULTS="/etc/default/limine"

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

[ -f "$LIMINE_DEFAULTS" ] || die "Missing ${LIMINE_DEFAULTS}"
command -v awk >/dev/null 2>&1 || die "awk is required."
command -v sudo >/dev/null 2>&1 || die "sudo is required."
command -v limine-update >/dev/null 2>&1 || die "limine-update is required."

ts="$(date +%Y%m%d%H%M%S)"
sudo cp -a "$LIMINE_DEFAULTS" "${LIMINE_DEFAULTS}.bak.${ts}"
printf '%s\n' "Backed up to ${LIMINE_DEFAULTS}.bak.${ts}"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

awk '
function trim(s) {
  sub(/^[[:space:]]+/, "", s)
  sub(/[[:space:]]+$/, "", s)
  return s
}

# Rewrite only the default kernel cmdline
match($0, /^(KERNEL_CMDLINE\[default\]\+\=\")([^\"]*)(\".*)$/, m) {
  prefix = m[1]
  cmd    = m[2]
  suffix = m[3]

  n = split(cmd, a, /[[:space:]]+/)
  out = ""

  for (i = 1; i <= n; i++) {
    tok = a[i]
    if (tok == "") continue

    # Drop existing splash/quiet so we can re-add cleanly
    if (tok == "quiet" || tok == "splash" || tok == "nosplash") continue

    # Drop the silent-boot flags you added earlier
    if (tok ~ /^loglevel=/) continue
    if (tok ~ /^systemd\.show_status=/) continue
    if (tok ~ /^rd\.udev\.log_level=/) continue
    if (tok ~ /^vt\.global_cursor_default=/) continue

    # Drop explicit Plymouth disable flags if present
    if (tok ~ /^plymouth\.enable=/) continue
    if (tok ~ /^rd\.plymouth=/) continue

    out = out (out ? " " : "") tok
  }

  out = trim(out)
  newcmd = "quiet splash" (out ? " " out : "")

  print prefix newcmd suffix
  next
}

{ print }
' "$LIMINE_DEFAULTS" > "$tmp"

sudo cp -a "$tmp" "$LIMINE_DEFAULTS"
printf '%s\n' "Updated ${LIMINE_DEFAULTS}"

sudo limine-update
printf '%s\n' "Ran limine-update"

printf '%s\n' "Done. Reboot to test the restored Plymouth LUKS prompt."