#!/usr/bin/env bash
pkill -x waybar 2>/dev/null
exec waybar
