#!/usr/bin/env bash

# Tmux Window Picker - Fuzzy find and switch between open tmux windows
# Usage: Bind this to a tmux key

if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is required for this script"
    exit 1
fi

# Get list of windows with their index, name, and path
# Format: "index: name (path)"
windows=$(tmux list-windows -F "#{window_index}: #{window_name} (#{pane_current_path})" | \
    sed "s|$HOME|~|g")

# Use fzf to select a window
selected=$(echo "$windows" | fzf --prompt="Switch to window: " --height=100% --reverse --border)

if [[ -z "$selected" ]]; then
    exit 0
fi

# Extract window index (everything before the first colon)
window_index=$(echo "$selected" | cut -d: -f1)

# Switch to the selected window
tmux select-window -t "$window_index"
