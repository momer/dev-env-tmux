#!/usr/bin/env bash
# Move current pane to another window using fzf
# Usage: move-pane-to-window.sh [v|h]
# v = vertical split (default), h = horizontal split

direction="${1:-v}"
cur=$(tmux display-message -p "#{window_index}")

# List windows excluding current, let user pick destination
dest=$(tmux list-windows -F "#{window_index}: #{window_name}" | grep -v "^$cur:" | \
  fzf -d: \
    --preview="$HOME/.tmux/scripts/preview-window-panes.sh {1}" \
    --preview-window=down,60% \
    --bind="ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up,ctrl-j:down,ctrl-k:up" | \
  cut -d: -f1)

# Move pane if destination selected
if [ -n "$dest" ]; then
  tmux join-pane -"$direction" -t :"$dest"
  tmux select-window -t :"$cur"
fi
