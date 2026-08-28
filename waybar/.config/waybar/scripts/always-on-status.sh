#!/bin/bash
# Waybar module: always-on (no-sleep) mode.
# Oneshot poll - prints one JSON object and exits.
set -u

UNIT=always-on.service

if systemctl --user is-active --quiet "$UNIT"; then
  # Open eye: nothing is allowed to interrupt the machine.
  printf '{"text":"\U000F0208","class":"active"}\n'
else
  # Closed eye: the default. Normal omarchy idle behaviour.
  printf '{"text":"\U000F0209","class":"sleeping"}\n'
fi
