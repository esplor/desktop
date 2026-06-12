#!/usr/bin/env sh
niri msg --json windows | jq -r 'sort_by(.workspace_id) | .[] |
  "app-id: \(.app_id)\(if .is_focused then " (focused)" else "" end)\ntitle: \(.title)\n"'
