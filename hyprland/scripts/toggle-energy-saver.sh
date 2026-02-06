#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
state_dir="${runtime_dir}/hypr"
state_file="${state_dir}/energy-saver.enabled"
profile_file="${state_dir}/energy-saver.profile"
monitor_file="${state_dir}/energy-saver.monitor"
visuals_file="${state_dir}/energy-saver.visuals"

monitor_name="eDP-1"
fallback_monitor="${monitor_name},1920x1080@120,0x0,1.0"
energy_monitor="${monitor_name},1920x1080@60,0x0,1.0"

notify() {
  local title="$1"
  local body="$2"

  if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Energy Saver" "$title" "$body" -r 8792 >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Energy Saver" "$title" "$body" >/dev/null 2>&1 || true
  fi
}

get_option_int() {
  local option="$1"
  hyprctl getoption "$option" 2>/dev/null | awk -F': ' '/int:/{print $2; exit}'
}

get_monitor_state() {
  hyprctl monitors 2>/dev/null | awk -v mon="$monitor_name" '
    $1=="Monitor" && $2==mon {found=1; next}
    found && $1 ~ /^[0-9]+x[0-9]+@/ {resrate=$1; pos=$3; next}
    found && $1=="scale:" {scale=$2; exit}
    END {
      if (resrate!="") {
        sub(/Hz$/, "", resrate);
        if (pos=="") pos="0x0";
        if (scale=="") scale="1.0";
        print mon "," resrate "," pos "," scale;
      }
    }'
}

save_visuals() {
  local blur shadow anim
  blur="$(get_option_int decoration:blur:enabled || true)"
  shadow="$(get_option_int decoration:shadow:enabled || true)"
  anim="$(get_option_int animations:enabled || true)"

  printf '%s %s %s\n' "${blur:-1}" "${shadow:-1}" "${anim:-1}" > "$visuals_file"
}

restore_visuals() {
  local blur shadow anim

  if [[ -f "$visuals_file" ]]; then
    read -r blur shadow anim < "$visuals_file"
  else
    blur=1
    shadow=1
    anim=1
  fi

  hyprctl keyword decoration:blur:enabled "$blur" >/dev/null
  hyprctl keyword decoration:shadow:enabled "$shadow" >/dev/null
  hyprctl keyword animations:enabled "$anim" >/dev/null
}

mkdir -p "$state_dir"

if [[ -f "$state_file" ]]; then
  if [[ -f "$profile_file" ]]; then
    powerprofilesctl set "$(cat "$profile_file")"
  else
    powerprofilesctl set balanced
  fi

  if [[ -f "$monitor_file" ]]; then
    hyprctl keyword monitor "$(cat "$monitor_file")" >/dev/null
  else
    hyprctl keyword monitor "$fallback_monitor" >/dev/null
  fi

  restore_visuals

  rm -f "$state_file"
  notify "Energy Saver" "Off"
  exit 0
fi

powerprofilesctl get > "$profile_file" 2>/dev/null || true

current_monitor="$(get_monitor_state || true)"
if [[ -n "$current_monitor" ]]; then
  printf '%s\n' "$current_monitor" > "$monitor_file"
fi

save_visuals

powerprofilesctl set power-saver
hyprctl keyword monitor "$energy_monitor" >/dev/null
hyprctl keyword decoration:blur:enabled 0 >/dev/null
hyprctl keyword decoration:shadow:enabled 0 >/dev/null
hyprctl keyword animations:enabled 0 >/dev/null

touch "$state_file"
notify "Energy Saver" "On"
