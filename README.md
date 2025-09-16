# Linux Configuration Files

This repository contains my personal Linux configuration files for various applications and tools.

## Contents

- **i3/**: i3 window manager configuration
  - `config`: Main i3 configuration file with keybindings, workspaces, and settings

- **fish/**: Fish shell configuration
  - `functions/fish_greeting.fish`: Custom greeting function with anime quotes

- **polybar/**: Polybar status bar configuration
  - `config.ini`: Main polybar configuration with modules and styling

## Installation

To use these configurations, copy the files to their respective locations:

```bash
# i3 config
cp i3/config ~/.config/i3/config

# Fish greeting function
mkdir -p ~/.config/fish/functions
cp fish/functions/fish_greeting.fish ~/.config/fish/functions/fish_greeting.fish

# Polybar config
mkdir -p ~/.config/polybar
cp polybar/config.ini ~/.config/polybar/config.ini
```

## Requirements

- i3 window manager
- Fish shell
- Polybar
- Various dependencies (see individual config files for details)

## Notes

- Some paths in the configurations may need to be adjusted for your system
- Font configurations assume specific fonts are installed
- Hardware-specific settings (like backlight card names) may need customization
