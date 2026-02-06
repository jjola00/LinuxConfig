#!/usr/bin/env bash
set -euo pipefail

WALLPAPERS_DIR="${WALLPAPERS_DIR:-$HOME/Pictures/wallpapers}"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$HOME/Downloads}"
HYPRPAPER_CONFIG="${HYPRPAPER_CONFIG:-$HOME/.config/hypr/hyprpaper/hyprpaper.conf}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="${RUNTIME_DIR}/hypr"
PAUSE_FILE="${STATE_DIR}/wallpaper-rotation.paused"
HOLD_FILE="${STATE_DIR}/wallpaper-rotation.hold"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}"
THUMB_DIR="${CACHE_ROOT}/hypr/wallpaper-thumbs"
THUMB_SIZE="${WALLPAPER_THUMB_SIZE:-128}"

notify() {
    local title="$1"
    local body="$2"

    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a "Wallpaper Engine" "$title" "$body" -r 8793 >/dev/null 2>&1 || true
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Wallpaper Engine" "$title" "$body" >/dev/null 2>&1 || true
    fi
}

ensure_hyprpaper() {
    if pgrep -x hyprpaper >/dev/null; then
        return 0
    fi

    hyprpaper --config "$HYPRPAPER_CONFIG" >/dev/null 2>&1 &
    sleep 0.2
}

thumb_for_wallpaper() {
    local src="$1"
    local hash thumb

    mkdir -p "$THUMB_DIR"
    if command -v sha1sum >/dev/null 2>&1; then
        hash="$(printf '%s' "$src" | sha1sum | awk '{print $1}')"
    else
        hash="$(printf '%s' "$src" | md5sum | awk '{print $1}')"
    fi

    thumb="$THUMB_DIR/$hash.png"
    if [[ ! -f "$thumb" || "$src" -nt "$thumb" ]]; then
        if command -v gdk-pixbuf-thumbnailer >/dev/null 2>&1; then
            gdk-pixbuf-thumbnailer -s "$THUMB_SIZE" "$src" "$thumb" >/dev/null 2>&1 || true
        elif command -v magick >/dev/null 2>&1; then
            magick "$src" -auto-orient -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}" "$thumb" >/dev/null 2>&1 || true
        elif command -v convert >/dev/null 2>&1; then
            convert "$src" -auto-orient -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}" "$thumb" >/dev/null 2>&1 || true
        fi
    fi

    if [[ -f "$thumb" ]]; then
        printf '%s\n' "$thumb"
    else
        printf '%s\n' "$src"
    fi
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

set_wallpaper() {
    local wallpaper="$1"

    if [[ ! -f "$wallpaper" ]]; then
        notify "Error" "Wallpaper not found"
        return 1
    fi

    ensure_hyprpaper
    wait_for_hyprpaper || true
    hyprctl hyprpaper preload "$wallpaper" 2>/dev/null
    if ! apply_wallpaper "$wallpaper"; then
        notify "Wallpaper error" "Failed to apply via hyprctl"
        return 1
    fi
    notify "Wallpaper set" "$(basename "$wallpaper")"
}

list_wallpapers() {
    local -a files=()
    local file

    if [[ ! -d "$WALLPAPERS_DIR" ]]; then
        notify "Error" "Wallpapers folder not found"
        return 1
    fi

    while IFS= read -r -d '' file; do
        files+=("${file#$WALLPAPERS_DIR/}")
    done < <(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -iname "background.png" ! -iname "lockscreen.png" -print0 | sort -z)

    if (( ${#files[@]} == 0 )); then
        return 1
    fi

    printf '%s\n' "${files[@]}"
}

pause_rotation() {
    mkdir -p "$STATE_DIR"
    touch "$PAUSE_FILE"
    notify "Rotation" "Paused"
}

resume_rotation() {
    rm -f "$PAUSE_FILE"
    rm -f "$HOLD_FILE"
    notify "Rotation" "Resumed"
}

set_hold_wallpaper() {
    local wallpaper="$1"
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$wallpaper" > "$HOLD_FILE"
}

unique_destination() {
    local src="$1"
    local name base ext dest

    name="$(basename "$src")"
    dest="$WALLPAPERS_DIR/$name"
    if [[ ! -e "$dest" ]]; then
        printf '%s\n' "$dest"
        return 0
    fi

    base="${name%.*}"
    ext="${name##*.}"
    if [[ "$base" == "$name" ]]; then
        ext=""
    fi

    local counter=1
    while :; do
        if [[ -n "$ext" ]]; then
            dest="$WALLPAPERS_DIR/${base}_${counter}.${ext}"
        else
            dest="$WALLPAPERS_DIR/${base}_${counter}"
        fi

        if [[ ! -e "$dest" ]]; then
            printf '%s\n' "$dest"
            return 0
        fi
        counter=$((counter + 1))
    done
}

import_from_downloads() {
    local -a files=()
    local file

    if [[ ! -d "$DOWNLOADS_DIR" ]]; then
        notify "Error" "Downloads folder not found"
        return 1
    fi

    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0)

    if (( ${#files[@]} == 0 )); then
        notify "No images" "Nothing to import from Downloads"
        return 0
    fi

    yad --question \
        --title="Import Wallpapers" \
        --text="Move ${#files[@]} image(s) from Downloads to Wallpapers?" \
        --center --on-top --skip-taskbar \
        --button="Yes:0" \
        --button="No:1" \
        2>/dev/null || return 0

    mkdir -p "$WALLPAPERS_DIR"

    local moved=0
    for file in "${files[@]}"; do
        local dest
        dest="$(unique_destination "$file")"
        mv -- "$file" "$dest"
        moved=$((moved + 1))
    done

    notify "Import complete" "Moved ${moved} image(s)"
}

delete_wallpaper() {
    local wallpaper="$1"
    local name
    name="$(basename "$wallpaper")"

    # Confirm deletion
    yad --question \
        --title="Delete Wallpaper" \
        --text="Delete '$name'?" \
        --center --on-top --skip-taskbar \
        --button="Yes:0" \
        --button="No:1" \
        2>/dev/null

    local confirm=$?
    if [[ $confirm -ne 0 ]]; then
        return 0
    fi

    # Actually delete the file
    if rm "$wallpaper" 2>/dev/null; then
        # Remove cached thumbnail
        local hash thumb
        if command -v sha1sum >/dev/null 2>&1; then
            hash="$(printf '%s' "$wallpaper" | sha1sum | awk '{print $1}')"
        else
            hash="$(printf '%s' "$wallpaper" | md5sum | awk '{print $1}')"
        fi
        thumb="$THUMB_DIR/$hash.png"
        rm -f "$thumb"
        notify "Deleted" "$name"
    else
        notify "Error" "Failed to delete $name"
    fi
}

get_status_text() {
    if [[ -f "$PAUSE_FILE" ]]; then
        echo "⏸  Paused"
    else
        echo "▶  Playing"
    fi
}

build_wallpaper_list() {
    local rel_path src thumb

    while IFS= read -r rel_path; do
        [[ -n "$rel_path" ]] || continue
        src="$WALLPAPERS_DIR/$rel_path"
        thumb="$(thumb_for_wallpaper "$src")"
        printf '%s\n%s\n%s\n' "$thumb" "$rel_path" "$src"
    done < <(list_wallpapers)
}

show_main_window() {
    local status
    status="$(get_status_text)"

    local wallpaper_data
    wallpaper_data="$(build_wallpaper_list)"

    if [[ -z "$wallpaper_data" ]]; then
        yad --info \
            --title="Wallpaper Engine" \
            --text="No wallpapers found in $WALLPAPERS_DIR" \
            --center --on-top --skip-taskbar \
            --button="Import:2" \
            --button="Close:1" \
            2>/dev/null
        local code=$?
        if [[ $code -eq 2 ]]; then
            import_from_downloads
            show_main_window
        fi
        return
    fi

    # Write to temp file to preserve exit code
    local tmpfile code result
    tmpfile=$(mktemp)

    # Disable errexit temporarily to capture yad's exit code
    set +e
    echo "$wallpaper_data" | yad --list \
        --title="Wallpaper Engine" \
        --text="<b>$status</b>" \
        --column=":IMG" \
        --column="Name" \
        --column="Path:HD" \
        --hide-column=3 \
        --print-column=3 \
        --width=700 \
        --height=500 \
        --center \
        --on-top \
        --skip-taskbar \
        --button="⏸ Pause:4" \
        --button="▶ Play:5" \
        --button="Set:0" \
        --button="Delete:2" \
        --button="Import:3" \
        --buttons-layout=center \
        2>/dev/null > "$tmpfile"
    code=$?
    set -e

    result=$(<"$tmpfile")
    rm -f "$tmpfile"

    # Clean up result (remove trailing | and newlines)
    result="${result%|}"
    result="${result%$'\n'}"
    result="$(echo "$result" | tr -d '\n\r')"

    # DEBUG: show what we got
    notify "Debug" "Code: $code | Result: '$result'"

    case $code in
        0) # Set wallpaper (button or double-click)
            if [[ -n "$result" && -f "$result" ]]; then
                pause_rotation
                set_hold_wallpaper "$result"
                set_wallpaper "$result"
            elif [[ -n "$result" ]]; then
                notify "Error" "File not found: $result"
            fi
            ;;
        1|252) # Close / Escape
            exit 0
            ;;
        2) # Delete
            if [[ -n "$result" && -f "$result" ]]; then
                delete_wallpaper "$result"
                show_main_window
            elif [[ -n "$result" ]]; then
                notify "Error" "File not found: $result"
                show_main_window
            else
                notify "Delete" "No wallpaper selected"
                show_main_window
            fi
            ;;
        3) # Import
            import_from_downloads
            show_main_window
            ;;
        4) # Pause
            pause_rotation
            ;;
        5) # Resume
            resume_rotation
            ;;
        *)
            exit 0
            ;;
    esac
}

main() {
    if ! command -v yad >/dev/null 2>&1; then
        notify "Missing dependency" "yad is not installed"
        exit 1
    fi

    show_main_window
}

main
