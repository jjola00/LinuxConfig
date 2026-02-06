#!/usr/bin/env bash
set -euo pipefail

shader_dir="$HOME/.config/hypr/shaders"
night_shader="$shader_dir/nightlight.frag"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
state_file="${runtime_dir}/hypr/.nightlight_state"
notify() {
  local title="$1"
  local body="$2"

  if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Night Light" "$title" "$body" -r 8791 >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Night Light" "$title" "$body" >/dev/null 2>&1 || true
  fi
}

get_current_shader() {
  hyprctl getoption decoration:screen_shader 2>/dev/null | awk -F': ' '/^str:/{print $2; exit}'
}

current="$(get_current_shader || true)"
current="${current%\"}"
current="${current#\"}"

if [[ -n "$current" ]]; then
  if [[ "$current" == "$night_shader" ]]; then
    target=""
  else
    target="$night_shader"
  fi
else
  if [[ -f "$state_file" ]]; then
    target=""
  else
    target="$night_shader"
  fi
fi

hyprctl keyword decoration:screen_shader "$target" >/dev/null

if [[ -n "$target" ]]; then
  mkdir -p "$(dirname "$state_file")"
  : > "$state_file"
  notify "Night Light" "On"
else
  rm -f "$state_file"
  notify "Night Light" "Off"
fi
