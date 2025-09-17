# 🐧 Le Linux Config Files

This repo is basically my Linux config files cus I have ptsdof sudden laptop switches and I am NOT going through config again

## 📂 Structure

- **i3/** – My i3 window manager setup
  - `config`
- **fish/** – Fish shell shenanigans
  - `functions/fish_greeting.fish`: Expect anime quotes. Lots of them
- **polybar/** – Polybar configs
  - `config.ini`

## 🚀 Installation (Copy-Paste Ritual)

### Quick Setup

```bash
# i3 config
cp i3/config ~/.config/i3/config

# Fish greeting function
mkdir -p ~/.config/fish/functions
cp fish/functions/fish_greeting.fish ~/.config/fish/functions/fish_greeting.fish

# Polybar config (the crown jewel of the rice)
mkdir -p ~/.config/polybar
cp polybar/config.ini ~/.config/polybar/config.ini
```
## 📦 Requirements

### Essential Packages
- **i3** 
- **fish**  
- **polybar**

### Optional Dependencies
- **rofi** - App launcher
- **feh** - Wallpaper setter
- **picom** - Compositor for transparency effects
- **Font Awesome** - For fancy icons in polybar

### Installation Commands

**Arch Linux:**
```bash
sudo pacman -S i3-wm fish polybar rofi feh picom ttf-font-awesome
```

**Ubuntu/Debian:**
```bash
sudo apt install i3 fish polybar rofi feh picom fonts-font-awesome
```

## ⚙️ Configuration Notes

### Fonts
These configs use **JetBrains Mono** and **Font Awesome**. If you don't have them....

### Hardware-Specific Settings
Some configs (like backlight controls) might need tweaks unless you happen to be me.
- `polybar/config.ini` - Battery and backlight modules
- `i3/config` - Media keys and system controls

### File Locations
All configs assume standard XDG config directories:
- `~/.config/i3/`
- `~/.config/fish/`  
- `~/.config/polybar/`

## ⚠️ Warnings & Disclaimers

```txt
 __        __               _             
 \ \      / /_ _ _ __ _ __ (_)_ __   __ _ 
  \ \ /\ / / _` | '__| '_ \| | '_ \ / _` |
   \ V  V / (_| | |  | | | | | | | | (_| |
    \_/\_/ \__,_|_|  |_| |_|_|_| |_|\__, |
                                   |___/ 
```

- **Backup your existing configs** before running anything
- Paths might not match your system - adjust as needed
- Some keybindings might conflict with your muscle memory