# Sourced by omarchy-menu after stock helpers. Use Ghostty instead of xdg-terminal-exec.

terminal() {
  setsid uwsm-app -- ghostty --gtk-single-instance=false --class=org.omarchy.terminal \
    -e "$1" "${@:2}"
}

present_terminal() {
  omarchy-launch-floating-terminal-with-presentation "$1"
}
