#!/usr/bin/env bash
# Preview all panes in a given window with layout info
# Usage: preview-window-panes.sh [session] window_index

# Handle both "session win" and just "win" formats
if [ $# -eq 2 ]; then
  session="$1"
  win="$2"
else
  session=""
  win="$1"
fi

# Skip preview for non-window selections
if [ "$win" = "[Select" ] || [ -z "$win" ]; then
  echo "Select a window to preview"
  exit 0
fi

# Build target (session:window or just :window)
if [ -n "$session" ]; then
  target="$session:$win"
else
  target=":$win"
fi

# Show window layout
pane_count=$(tmux list-panes -t "$target" 2>/dev/null | wc -l)
if [ "$pane_count" -eq 0 ]; then
  echo "No panes found"
  exit 0
fi

echo "Window $win | $pane_count pane(s)"
echo "----------------------------------------"

# Show each pane with position info
tmux list-panes -t "$target" -F "#P #{pane_width}x#{pane_height} (#{pane_top},#{pane_left}) #{pane_current_command}" | while read -r line; do
  pane_idx=$(echo "$line" | awk '{print $1}')
  pane_info=$(echo "$line" | cut -d' ' -f2-)
  echo ""
  echo "=== Pane $pane_idx: $pane_info ==="
  tmux capture-pane -ep -t "$target"."$pane_idx" | head -20
done
