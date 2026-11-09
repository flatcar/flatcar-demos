#!/usr/bin/env bash
#
# tmux session with two panes side by side, so one asciinema recording
# shows both:
#   - left:  the Flatcar boot console (run.sh)
#   - right: an SSH-ready shell, once sshd is reachable
#
# The ssh command is not run for you. wait-for-ssh.sh waits for port 2222,
# then gives you a prompt to type ssh and follow-up commands live.
#
# Note: this uses tmux's default Ctrl-b prefix. If you rebound your prefix
# to Ctrl-a, that is also QEMU's escape key (Ctrl-a x), and tmux takes it
# first.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

SESSION="flatcar-demo"

tmux kill-session -t "$SESSION" 2>/dev/null || true

tmux new-session -d -s "$SESSION" -x 220 -y 50 './run.sh'
tmux split-window -h -t "$SESSION" './wait-for-ssh.sh'

tmux set-option -t "$SESSION" -g pane-border-status top
tmux set-option -t "$SESSION" -g pane-border-format "#{pane_title}"
tmux select-pane -t "${SESSION}:0.0" -T "Flatcar boot (serial console)"
tmux select-pane -t "${SESSION}:0.1" -T "SSH session"

tmux select-pane -t "${SESSION}:0.0"
tmux attach-session -t "$SESSION"
