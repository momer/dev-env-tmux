#!/usr/bin/env bash
# Preview all panes in a given window with layout info
win="$1"

# Show window layout
layout=$(tmux display-message -p -t :"$win" '#{window_layout}')
pane_count=$(tmux list-panes -t :"$win" | wc -l)
echo "Window $win | $pane_count pane(s)"
echo "----------------------------------------"

# Show each pane with position info
tmux list-panes -t :"$win" -F "#P #{pane_width}x#{pane_height} (#{pane_top},#{pane_left}) #{pane_current_command}" | while read -r line; do
  pane_idx=$(echo "$line" | awk '{print $1}')
  pane_info=$(echo "$line" | cut -d' ' -f2-)
  echo ""
  echo "=== Pane $pane_idx: $pane_info ==="
  tmux capture-pane -ep -t :"$win"."$pane_idx" | head -20
done
