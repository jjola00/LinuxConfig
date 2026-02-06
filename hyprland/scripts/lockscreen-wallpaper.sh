#!/bin/bash

# Enhanced hyprlock lockscreen with random wallpapers
# Rose Pine Moon themed

LOCKPAPERS_DIR="$HOME/Pictures/wallpapers"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="${RUNTIME_DIR}/hypr"
PAUSE_FILE="${STATE_DIR}/wallpaper-rotation.paused"
HOLD_FILE="${STATE_DIR}/wallpaper-rotation.hold"

IMG_PATH=""
if [[ -f "$PAUSE_FILE" ]]; then
    if [[ -f "$HOLD_FILE" ]]; then
        IMG_PATH="$(cat "$HOLD_FILE")"
        if [[ -n "$IMG_PATH" && ! -f "$IMG_PATH" ]]; then
            IMG_PATH=""
        fi
    fi
else
    if [ -d "$LOCKPAPERS_DIR" ] && [ "$(ls -A "$LOCKPAPERS_DIR")" ]; then
        IMG=$(ls "$LOCKPAPERS_DIR" | shuf -n 1)
        IMG_PATH="$LOCKPAPERS_DIR/$IMG"
    fi
fi

if [[ -n "$IMG_PATH" ]]; then
    
    # Create temporary hyprlock config with selected wallpaper
    TEMP_CONFIG="/tmp/hyprlock_temp.conf"
    cp ~/.config/hypr/hyprlock.conf "$TEMP_CONFIG"
    
    # Replace the screenshot background with our random wallpaper
    sed -i "s|path = screenshot|path = $IMG_PATH|g" "$TEMP_CONFIG"
    
    # Launch hyprlock with temporary config
    hyprlock --config "$TEMP_CONFIG"
    
    # Clean up
    rm -f "$TEMP_CONFIG"
else
    echo "No wallpapers found or rotation paused without a hold wallpaper; using screenshot background"
    hyprlock
fi
