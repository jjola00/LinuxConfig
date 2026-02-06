#!/usr/bin/env bash
set -euo pipefail

record_dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/recordings"
state_dir="${XDG_RUNTIME_DIR:-/tmp}/hypr-recorder"
pidfile="$state_dir/wf-recorder.pid"
lastfile="$state_dir/last_recording"

notify() {
  local title="$1"
  local body="${2:-}"

  if command -v dunstify >/dev/null 2>&1; then
    dunstify "$title" "$body"
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body"
  else
    printf '%s\n' "$title${body:+: $body}"
  fi
}

if ! command -v wf-recorder >/dev/null 2>&1; then
  notify "Screen recording failed" "wf-recorder not found"
  exit 1
fi

mkdir -p "$state_dir"

if pgrep -x wf-recorder >/dev/null 2>&1; then
  pkill -INT -x wf-recorder || true
  if [ -f "$lastfile" ]; then
    saved="$(cat "$lastfile")"
    notify "Screen recording saved" "$saved"
  else
    notify "Screen recording stopped"
  fi
  exit 0
fi

mkdir -p "$record_dir"
timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
file="$record_dir/${timestamp}.mp4"

wf-recorder -f "$file" >/dev/null 2>&1 &
echo "$!" > "$pidfile"
echo "$file" > "$lastfile"
notify "Screen recording started" "$file"
