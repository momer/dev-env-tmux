#!/usr/bin/env bash
# Move current pane to another window using fzf
# Usage: move-pane-to-window.sh [v|h] [session_name]
# v = vertical split (default), h = horizontal split
# session_name = target session (defaults to current session)

direction="${1:-v}"
target_session="${2:-$(tmux display-message -p '#{session_name}')}"
cur_session=$(tmux display-message -p "#{session_name}")
cur_win=$(tmux display-message -p "#{window_index}")

# Build window list with session selection option at top
select_session_opt="[Select Session...]"

show_window_picker() {
  local session="$1"
  local exclude_win=""

  # Only exclude current window if in same session
  if [ "$session" = "$cur_session" ]; then
    exclude_win="$cur_win"
  fi

  # Build window list
  windows=$(tmux list-windows -t "$session" -F "#{window_index}: #{window_name}" | \
    if [ -n "$exclude_win" ]; then grep -v "^$exclude_win:"; else cat; fi)

  # Add session selector option at top with separator
  echo "$windows"
  echo ""
  echo "$select_session_opt"
}

# Show session picker
show_session_picker() {
  tmux list-sessions -F "#{session_name}" | \
    fzf --header="Select session (current: $cur_session)" \
        --preview="tmux list-windows -t {} -F '  #{window_index}: #{window_name}'" \
        --preview-window=down,40% \
        --bind="ctrl-j:down,ctrl-k:up"
}

# Main selection loop
selected_session="$target_session"

while true; do
  selection=$(show_window_picker "$selected_session" | \
    fzf -d: \
      --header="Session: $selected_session" \
      --preview="$HOME/.tmux/scripts/preview-window-panes.sh $selected_session {1}" \
      --preview-window=down,60% \
      --bind="ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up,ctrl-j:down,ctrl-k:up")

  # Handle session selection option
  if [ "$selection" = "$select_session_opt" ]; then
    new_session=$(show_session_picker)
    if [ -n "$new_session" ]; then
      selected_session="$new_session"
      continue
    else
      exit 0
    fi
  fi

  break
done

# Extract window index from selection
dest=$(echo "$selection" | cut -d: -f1)

# Move pane if destination selected
if [ -n "$dest" ]; then
  tmux join-pane -"$direction" -t "$selected_session":"$dest"
  # Stay in original session/window
  tmux select-window -t "$cur_session":"$cur_win"
fi
