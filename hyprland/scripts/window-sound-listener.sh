#!/usr/bin/env bash
# Play a short sound whenever Hyprland reports a new window

set -euo pipefail

sock="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

# Only run inside Hyprland
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || [ ! -S "$sock" ]; then
    exit 0
fi

player="${HOME}/.local/bin/play-sound"
if [ ! -x "$player" ]; then
    exit 0
fi

# Listen for openwindow events from Hyprland IPC
socat -u UNIX-CONNECT:"$sock" - 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        openwindow*|openwindow>>*)
            "$player" window-open
            ;;
    esac
done
