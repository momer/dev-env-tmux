#!/usr/bin/env bash
# Move current pane to another window using fzf
# Usage: move-pane-to-window.sh [v|h] [session_name]
# v = vertical split (default), h = horizontal split
# session_name = target session (defaults to current session)

direction="${1:-v}"
target_session="${2:-$(tmux display-message -p '#{session_name}')}"
cur_session=$(tmux display-message -p "#{session_name}")
cur_win=$(tmux display-message -p "#{window_index}")

# Options for session management
select_session_opt="[Select Session...]"
new_session_opt="[New Session...]"

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

  # Add session options at bottom with separator
  echo "$windows"
  echo ""
  echo "$select_session_opt"
  echo "$new_session_opt"
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

  # Handle new session creation
  if [ "$selection" = "$new_session_opt" ]; then
    session_name=$(echo "" | fzf --print-query --prompt="New session name: " --header="Enter name for new session" | head -1)
    if [ -n "$session_name" ]; then
      # Create detached session, move pane there, remove empty initial pane
      tmux new-session -d -s "$session_name"
      tmux join-pane -"$direction" -t "$session_name":0
      # Kill the empty pane that was created with the session (it's now pane 0)
      tmux kill-pane -t "$session_name":0.0
      tmux select-window -t "$cur_session":"$cur_win"
      exit 0
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
