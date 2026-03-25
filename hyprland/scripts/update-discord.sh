#!/usr/bin/env bash
# Download the latest Discord .deb, install it via sudo (rofi password prompt),
# clean up old .deb files, and launch Discord.

set -uo pipefail

DOWNLOAD_DIR="$HOME/Downloads"
DISCORD_URL="https://discord.com/api/download?platform=linux&format=deb"
NOTIFY_ID=9999
ROFI_THEME="$HOME/.config/rofi/discord-password.rasi"
LOG="/tmp/discord-update.log"

exec > >(tee -a "$LOG") 2>&1
echo "=== Discord update started at $(date) ==="

notify() { dunstify -a "Discord" -r "$NOTIFY_ID" "$1" "$2" 2>/dev/null; }

notify "Discord Update" "Downloading latest .deb..."

# Download the latest deb (follows redirects, keeps server filename)
WGET_OUT=$(wget --content-disposition -P "$DOWNLOAD_DIR" "$DISCORD_URL" 2>&1) || true
echo "wget output: $WGET_OUT"

# Try to find the saved filename from wget output
DEB_FILE=$(echo "$WGET_OUT" | grep -oP "'\K$DOWNLOAD_DIR/[^']+" | head -1) || true

# Fallback: find the newest discord*.deb in Downloads
if [[ -z "$DEB_FILE" || ! -f "$DEB_FILE" ]]; then
    echo "grep failed, falling back to newest discord deb in $DOWNLOAD_DIR"
    DEB_FILE=$(ls -t "$DOWNLOAD_DIR"/discord*.deb 2>/dev/null | head -1) || true
fi

if [[ -z "$DEB_FILE" || ! -f "$DEB_FILE" ]]; then
    notify "Discord Update" "Download failed! Check /tmp/discord-update.log"
    exit 1
fi

DEB_BASENAME=$(basename "$DEB_FILE")
echo "Using deb: $DEB_FILE"

notify "Discord Update" "Installing $DEB_BASENAME..."

# Ask for sudo password via rofi popup
PASSWD=$(rofi -dmenu -p "sudo password" -password -theme "$ROFI_THEME" -lines 0 -no-fixed-num-lines < /dev/null || true)

if [[ -z "$PASSWD" ]]; then
    notify "Discord Update" "Cancelled - no password provided."
    exit 1
fi

# Install the deb
if echo "$PASSWD" | sudo -S dpkg -i "$DEB_FILE" 2>&1; then
    # Fix any missing dependencies
    echo "$PASSWD" | sudo -S apt-get install -f -y 2>&1

    notify "Discord Update" "Installed! Cleaning up old .deb files..."

    # Remove all discord .deb files except the one we just installed
    # Catches: discord*.deb, discord*.deb.1, discord*.deb (2), etc.
    for f in "$DOWNLOAD_DIR"/discord*.deb*; do
        [[ "$f" != "$DEB_FILE" ]] && rm -f "$f"
    done
    for f in "$DOWNLOAD_DIR"/discord*\.deb\ *; do
        [[ -f "$f" && "$f" != "$DEB_FILE" ]] && rm -f "$f"
    done

    notify "Discord Update" "Done! Launching Discord..."
    discord &
else
    notify "Discord Update" "Installation failed! Check /tmp/discord-update.log"
    exit 1
fi
