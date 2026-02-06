#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
state_dir="${runtime_dir}/hypr"
state_file="${state_dir}/spotify-volume"

notify() {
  local title="$1"
  local body="$2"

  if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Spotify" "$title" "$body" -r 8793 >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Spotify" "$title" "$body" >/dev/null 2>&1 || true
  fi
}

if ! command -v playerctl >/dev/null 2>&1; then
  notify "Spotify" "playerctl not found"
  exit 1
fi

if ! playerctl -p spotify status >/dev/null 2>&1; then
  notify "Spotify" "Not running"
  exit 0
fi

current="$(playerctl -p spotify volume 2>/dev/null || true)"
if [[ -z "$current" ]]; then
  notify "Spotify" "Unable to read volume"
  exit 1
fi

is_muted="$(awk -v v="$current" 'BEGIN { if (v <= 0.001) print 1; else print 0 }')"

if [[ "$is_muted" -eq 0 ]]; then
  mkdir -p "$state_dir"
  printf '%s\n' "$current" > "$state_file"
  playerctl -p spotify volume 0
  notify "Spotify" "Muted"
else
  if [[ -f "$state_file" ]]; then
    target="$(cat "$state_file")"
  else
    target="0.5"
  fi
  playerctl -p spotify volume "$target"
  rm -f "$state_file"
  notify "Spotify" "Unmuted"
fi
