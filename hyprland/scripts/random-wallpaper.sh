#!/bin/bash

# Hyprpaper wallpaper rotation script
# Changes wallpaper every WALLPAPER_INTERVAL seconds (default: 60s earlier, now 180s to reduce I/O thrash)

set -euo pipefail

WALLPAPERS_DIR="${WALLPAPERS_DIR:-$HOME/Pictures/wallpapers}"
WALLPAPER_INTERVAL="${WALLPAPER_INTERVAL:-180}"
# Rescan the directory after N rotations to pick up new images without hitting the disk every loop.
WALLPAPER_REFRESH_INTERVAL="${WALLPAPER_REFRESH_INTERVAL:-20}"
HYPRPAPER_CONFIG="${HYPRPAPER_CONFIG:-$HOME/.config/hypr/hyprpaper/hyprpaper.conf}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="${RUNTIME_DIR}/hypr"
PAUSE_FILE="${STATE_DIR}/wallpaper-rotation.paused"

declare -a WALLPAPER_LIST=()
rotation_counter=0

log() {
    printf '%s: %s\n' "$(date '+%F %T')" "$*"
}

rotation_paused() {
    [[ -f "$PAUSE_FILE" ]]
}

wait_for_hyprpaper() {
    ensure_hyprpaper
    local attempts=30
    while (( attempts-- > 0 )); do
        if hyprctl hyprpaper monitors >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.2
    done
    return 1
}

list_monitors() {
    hyprctl monitors 2>/dev/null | awk '/^Monitor /{print $2}'
}

apply_wallpaper() {
    local wallpaper="$1"
    local -a monitors=()
    local name

    while IFS= read -r name; do
        [[ -n "$name" ]] || continue
        monitors+=("$name")
    done < <(list_monitors)

    if (( ${#monitors[@]} == 0 )); then
        hyprctl hyprpaper wallpaper ",$wallpaper" 2>/dev/null
        return $?
    fi

    local applied=0
    for name in "${monitors[@]}"; do
        if hyprctl hyprpaper wallpaper "$name,$wallpaper" 2>/dev/null; then
            applied=1
        fi
    done

    (( applied == 1 ))
}

ensure_hyprpaper() {
    if pgrep -x hyprpaper >/dev/null; then
        return 0
    fi

    hyprpaper --config "$HYPRPAPER_CONFIG" >/dev/null 2>&1 &
    sleep 0.2
}

refresh_wallpaper_list() {
    WALLPAPER_LIST=()

    if [[ ! -d "$WALLPAPERS_DIR" ]]; then
        log "Wallpapers directory $WALLPAPERS_DIR not found"
        return 1
    fi

    while IFS= read -r -d '' file; do
        WALLPAPER_LIST+=("$file")
    done < <(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -iname "background.png" ! -iname "lockscreen.png" -print0)

    if [[ ${#WALLPAPER_LIST[@]} -eq 0 ]]; then
        log "No valid wallpaper files found under $WALLPAPERS_DIR"
        return 1
    fi

    log "Loaded ${#WALLPAPER_LIST[@]} wallpapers from $WALLPAPERS_DIR"
}

pick_random_wallpaper() {
    local total=${#WALLPAPER_LIST[@]}
    if (( total == 0 )); then
        return 1
    fi

    local index=$((RANDOM % total))
    printf '%s\n' "${WALLPAPER_LIST[$index]}"
}

set_random_wallpaper() {
    local wallpaper
    if ! wallpaper="$(pick_random_wallpaper)"; then
        refresh_wallpaper_list || return 1
        wallpaper="$(pick_random_wallpaper)" || return 1
    fi

    log "Setting wallpaper: $(basename "$wallpaper")"
    if ! hyprctl hyprpaper preload "$wallpaper" 2>/dev/null; then
        ensure_hyprpaper
        wait_for_hyprpaper || return 1
    fi

    hyprctl hyprpaper preload "$wallpaper" 2>/dev/null
    apply_wallpaper "$wallpaper"
}

# Initial load and wallpaper set (wait for hyprpaper to accept commands)
if wait_for_hyprpaper; then
    if rotation_paused; then
        log "Rotation paused; skipping initial set"
    else
        refresh_wallpaper_list && set_random_wallpaper
    fi
else
    log "hyprpaper did not become ready in time; skipping initial set"
fi

while true; do
    if rotation_paused; then
        sleep 2
        continue
    fi

    sleep "$WALLPAPER_INTERVAL"
    if rotation_paused; then
        continue
    fi
    if ! set_random_wallpaper; then
        # Try again after a quick pause if the first attempt failed.
        sleep 5
        refresh_wallpaper_list && set_random_wallpaper
    fi

    rotation_counter=$(((rotation_counter + 1) % WALLPAPER_REFRESH_INTERVAL))
    if (( rotation_counter == 0 )); then
        refresh_wallpaper_list || true
    fi
done
