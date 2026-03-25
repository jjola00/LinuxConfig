# ~/.config/fish/config.fish

if status is-interactive

    # Set colors
    set fish_color_user purple
    set fish_color_quote green
    set fish_color_error orange
    set fish_color_operator blue
    set fish_color_autosuggestion magenta
    set fish_color_cwd_root green
    set fish_color_host purple
    set fish_color_cancel magenta

    set fish_pager_color_prefix green
    set fish_pager_color_completion green
    set fish_pager_color_description red
    set fish_pager_color_background --background=black
    set fish_pager_color_secondary_background --background=black

    if string match -q "kiro" "$TERM_PROGRAM"
        if test -x /usr/bin/kiro
            . (/usr/bin/kiro --locate-shell-integration-path fish)
        end
    end
end
alias pgstart='sudo systemctl start postgresql@16-main.service'

# Force Electron apps to use Wayland
set -gx ELECTRON_OZONE_PLATFORM_HINT auto

set -gx SUDO_PROMPT "pass? 🥺👉👈 "

# Wayland-enabled app aliases
alias code='env ELECTRON_OZONE_PLATFORM_HINT=auto code --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations'
alias spotify='spotify --enable-features=UseOzonePlatform --ozone-platform=wayland'
# Image file management aliases
alias cpjpg 'cp *.jpg ~/Pictures/wallpapers/ 2>/dev/null; or echo "No JPG files found or destination not accessible"'
alias cppng 'cp *.png ~/Pictures/wallpapers/ 2>/dev/null; or echo "No PNG files found or destination not accessible"'
alias rmjpg 'rm -i *.jpg 2>/dev/null; or echo "No JPG files found"'
alias rmpng 'rm -i *.png 2>/dev/null; or echo "No PNG files found"'
alias gs='git status'
alias a='git add -A'
alias p='git push'
alias ac='source venv/bin/activate.fish'
alias pass='cat ~/gittoken.txt'
