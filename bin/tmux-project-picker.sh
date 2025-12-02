#!/usr/bin/env bash

# Tmux Project Picker - Quickly open projects in new tmux windows
# Usage: Bind this to a tmux key or run directly

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/wsgr/neuron}"

# Find all subdirectories (projects) - you can customize the depth
# Using find with maxdepth 1 for immediate subdirectories
if command -v fzf >/dev/null 2>&1; then
    # Use fzf for fuzzy finding
    selected=$(find "$PROJECT_ROOT" -mindepth 1 -maxdepth 1 -type d | \
        sed "s|$PROJECT_ROOT/||" | \
        sort | \
        fzf --prompt="Select Project: " --height=100% --reverse --border)
else
    # Fallback to simple list selection
    echo "Installing fzf is recommended for better experience"
    echo "Available projects:"
    projects=($(find "$PROJECT_ROOT" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort))
    select selected in "${projects[@]}"; do
        break
    done
fi

if [[ -z "$selected" ]]; then
    exit 0
fi

# Full path to selected project
project_path="$PROJECT_ROOT/$selected"

# Sanitize project name for tmux window name (replace dots, slashes, etc.)
window_name=$(echo "$selected" | tr '.' '_' | tr '/' '_')

# Check if we're in a tmux session
if [[ -n "$TMUX" ]]; then
    # Check if window with this name already exists
    if tmux list-windows -F "#{window_name}" | grep -q "^${window_name}$"; then
        # Switch to existing window
        tmux select-window -t "$window_name"
    else
        # Create new window and switch to project directory
        tmux new-window -n "$window_name" -c "$project_path"
        # Optionally, open nvim automatically
        # tmux send-keys -t "$window_name" "nvim ." C-m
    fi
else
    # Not in tmux, create new session or attach to existing
    if tmux has-session -t "$window_name" 2>/dev/null; then
        tmux attach-session -t "$window_name"
    else
        tmux new-session -s "$window_name" -c "$project_path"
    fi
fi
