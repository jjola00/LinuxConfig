#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/web-search.rasi"
query="$(rofi -dmenu -i -p "Search" -theme "$theme" -lines 0 -no-fixed-num-lines < /dev/null || true)"

if [[ -z "${query//[[:space:]]/}" ]]; then
  exit 0
fi

encoded="$(python3 -c 'import sys, urllib.parse as u; print(u.quote_plus(sys.argv[1]))' "$query")"

new_ws=""
if command -v hyprctl >/dev/null 2>&1; then
  workspaces_json="$(hyprctl workspaces -j 2>/dev/null || true)"
  if [[ -n "$workspaces_json" ]]; then
    new_ws="$(python3 - <<'PY' "$workspaces_json"
import json
import sys

try:
    data = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)

ids = {w.get("id") for w in data if isinstance(w, dict) and isinstance(w.get("id"), int)}
ws = 1
while ws in ids:
    ws += 1

print(ws)
PY
    )"
  fi
fi

if [[ -n "$new_ws" ]]; then
  hyprctl dispatch workspace "$new_ws" >/dev/null 2>&1 || true
fi

exec google-chrome --new-window "https://claude.ai/new?q=${encoded}"
