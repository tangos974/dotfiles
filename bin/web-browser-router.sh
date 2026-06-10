#!/bin/bash
# Default-browser dispatcher: send web-conferencing links to Brave (which
# handles WebRTC/camera/mic fine) and everything else to Mullvad Browser
# (the general default). Set as the system default web browser via a
# .desktop named `mullvad-browser-webrouter.desktop` — that name still
# matches omarchy-launch-webapp's `mullvad-browser*` glob, so SUPER+SHIFT
# webapps keep going straight to Mullvad and never touch this router.
#
# Brave runs as the only webapp/conferencing browser here; see
# dotfiles/brave-policies for its managed policy.

for arg in "$@"; do
  case "$arg" in
    *://meet.google.com/*|*://meet.google.com \
    |*://*.zoom.us/*|*://zoom.us/* \
    |*://teams.microsoft.com/*|*://teams.live.com/* \
    |*://*.webex.com/*|*://webex.com/* \
    |*://meet.jit.si/* \
    |*://*.whereby.com/*|*://whereby.com/*)
      exec setsid uwsm-app -- brave --new-window "$arg"
      ;;
  esac
done

# Not a conferencing link (or a flag / no URL): hand off to Mullvad.
# Callers that want a uwsm scope (omarchy-launch-browser) already wrap us.
exec mullvad-browser "$@"
