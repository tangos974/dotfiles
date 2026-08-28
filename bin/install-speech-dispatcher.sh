#!/bin/sh
# Install speech-dispatcher and point it at FastKoko (Kokoro-FastAPI) on
# http://inference.home:8880 via a generic output module, so anything speaking
# through speechd (spd-say, browser readers, orca, ...) uses the homelab TTS.
set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=dotfiles-stow.sh
. "$SCRIPT_DIR/dotfiles-stow.sh"

# jq/curl/mpv are the module's runtime dependencies.
yay -S --needed --noconfirm speech-dispatcher jq curl mpv

# speechd.conf + modules/kokoro.conf -> ~/.config/speech-dispatcher/
# kokoro-speak -> ~/.local/bin/
stow_pkg speech-dispatcher

# Pick up config changes if a daemon is already running (autospawns otherwise).
# -f because "speech-dispatcher" exceeds pkill's 15-char comm-name limit;
# [s] so the pattern can't match this script's own command line.
pkill -u "$(id -u)" -f '[s]peech-dispatcher' 2>/dev/null || true

echo 'speech-dispatcher -> FastKoko ready. Test with: spd-say "hello world"'
