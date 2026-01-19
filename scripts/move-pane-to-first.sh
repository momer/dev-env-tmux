#!/usr/bin/env bash
# Move current pane to first position (far left)
set -euo pipefail

# Get current pane info
current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')
pane_count=$(tmux display-message -p '#{window_panes}')

# Nothing to do if only one pane
if [ "$pane_count" -le 1 ]; then
  exit 0
fi

# Store in temp window
if ! tmux break-pane -d -s "$current_pane"; then
  exit 1
fi

# Join back at the beginning; if this fails, pane is in a new window (recoverable)
if ! tmux join-pane -fhb -s "$current_pane" -t "$current_window"; then
  tmux display-message "Failed to rejoin pane - check for orphaned window"
  exit 1
fi
