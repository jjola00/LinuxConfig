#!/bin/bash

# Manual wallpaper changer script
# Changes wallpaper immediately when called

WALLPAPERS_DIR="$HOME/Pictures/wallpapers"
HYPRPAPER_CONFIG="${HYPRPAPER_CONFIG:-$HOME/.config/hypr/hyprpaper/hyprpaper.conf}"

ensure_hyprpaper() {
    if pgrep -x hyprpaper >/dev/null; then
        return 0
    fi

    hyprpaper --config "$HYPRPAPER_CONFIG" >/dev/null 2>&1 &
    sleep 0.2
}

wait_for_hyprpaper() {
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

if [ -d "$WALLPAPERS_DIR" ] && [ "$(ls -A $WALLPAPERS_DIR)" ]; then
    # Get a random wallpaper (support multiple formats) while skipping placeholder images
    WALLPAPER=$(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -iname "background.png" ! -iname "lockscreen.png" | shuf -n 1)
    
    if [ -n "$WALLPAPER" ]; then
        echo "Manual wallpaper change: $(basename "$WALLPAPER")"
        
        ensure_hyprpaper
        wait_for_hyprpaper || true

        # Preload the wallpaper first
        hyprctl hyprpaper preload "$WALLPAPER" 2>/dev/null
        
        # Set it as wallpaper on all monitors
        if ! apply_wallpaper "$WALLPAPER"; then
            notify-send "Error" "Failed to apply wallpaper" -t 2000
        fi
        
        # Show notification (optional)
        notify-send "Wallpaper Changed" "$(basename "$WALLPAPER")" -t 2000
    else
        notify-send "Error" "No valid wallpaper files found" -t 2000
    fi
else
    notify-send "Error" "Wallpapers directory not found" -t 2000
fi
