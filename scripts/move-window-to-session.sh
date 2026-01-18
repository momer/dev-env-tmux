#!/usr/bin/env bash
# Move current window to another session using fzf
# Usage: move-window-to-session.sh

cur_session=$(tmux display-message -p "#{session_name}")
cur_win=$(tmux display-message -p "#{window_index}")

# Options
new_session_opt="[New Session...]"

# Show session picker
show_session_picker() {
  # List sessions excluding current
  sessions=$(tmux list-sessions -F "#{session_name}" | grep -v "^${cur_session}$")

  echo "$sessions"
  echo ""
  echo "$new_session_opt"
}

selection=$(show_session_picker | \
  fzf --header="Move window to session (current: $cur_session)" \
      --preview="tmux list-windows -t {} -F '  #{window_index}: #{window_name}'" \
      --preview-window=down,40% \
      --bind="ctrl-j:down,ctrl-k:up")

# Handle new session creation
if [ "$selection" = "$new_session_opt" ]; then
  session_name=$(echo "" | fzf --print-query --prompt="New session name: " --header="Enter name for new session" | head -1)
  if [ -n "$session_name" ]; then
    # Create session and move window there, then kill empty initial window
    tmux new-session -d -s "$session_name"
    tmux move-window -t "$session_name"
    # Kill the empty window that was created with the session (now index 0)
    tmux kill-window -t "$session_name":0
  fi
  exit 0
fi

# Move window if session selected
if [ -n "$selection" ]; then
  tmux move-window -t "$selection":
fi
