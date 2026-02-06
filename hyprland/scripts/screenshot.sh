#!/usr/bin/env bash
set -euo pipefail

mode="${1:-full}"
dir="${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/screenshots}"
mkdir -p "$dir"

timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
file="$dir/${timestamp}.png"

cleanup_empty() {
  if [ -f "$file" ] && [ ! -s "$file" ]; then
    rm -f "$file"
  fi
}
trap cleanup_empty EXIT

case "$mode" in
  area)
    grim -g "$(slurp)" - | tee "$file" | wl-copy
    label="Area"
    ;;
  full|screen)
    grim - | tee "$file" | wl-copy
    label="Full screen"
    ;;
  *)
    echo "Usage: $0 [area|full]" >&2
    exit 1
    ;;
esac

dunstify "Screenshot saved" "$label -> $file"
play-sound camera-shutter
