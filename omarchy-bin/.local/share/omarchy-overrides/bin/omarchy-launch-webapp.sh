#!/bin/sh

# Redirect standard WebApp calls to Firefox WebApp profile
browser=$(xdg-settings get default-web-browser)

case $browser in
firefox* )
    # Launch Firefox directly with the dedicated WebApp profile
    exec setsid uwsm app -- firefox --no-remote -P "WebApps" --new-window --class WebApp "$1" "${@:2}"
    ;;
*)
    # Old Chromium fallback for other browsers if needed
    browser="chromium.desktop"
    exec setsid uwsm app -- $(sed -n 's/^Exec=\([^ ]*\).*/\1/p' {~/.local,~/.nix-profile,/usr}/share/applications/$browser 2>/dev/null | head -1) --app="$1" "${@:2}"
    ;;
esac
