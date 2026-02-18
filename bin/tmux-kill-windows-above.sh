#!/bin/bash
# Kill all tmux windows with index greater than the given number
n=$1
for i in $(tmux list-windows -F '#{window_index}' | awk -v n="$n" '$1 > n' | sort -rn); do
  tmux kill-window -t ":$i"
done
