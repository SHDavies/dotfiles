#!/usr/bin/env bash

# Tmux Join Pane Picker - Fuzzy find a window and join it as a side-by-side pane
# Usage: Bind this to a tmux key

if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is required for this script"
    exit 1
fi

current_window=$(tmux display-message -p "#{window_index}")

# Get list of windows excluding the current one
windows=$(tmux list-windows -F "#{window_index}: #{window_name} (#{pane_current_path})" | \
    grep -v "^${current_window}:" | \
    sed "s|$HOME|~|g")

if [[ -z "$windows" ]]; then
    echo "No other windows to join"
    exit 0
fi

# Use fzf to select a window
selected=$(echo "$windows" | fzf --prompt="Join pane from window: " --height=100% --reverse --border)

if [[ -z "$selected" ]]; then
    exit 0
fi

# Extract window index (everything before the first colon)
window_index=$(echo "$selected" | cut -d: -f1)

# Join the selected window's pane into the current window side-by-side
tmux join-pane -h -s ":${window_index}"
