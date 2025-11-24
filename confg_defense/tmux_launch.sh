#!/usr/bin/env bash

SESSION_NAME="pdcp-defense"

# Create a new tmux session in the background
tmux new-session -d -s "$SESSION_NAME" -n main

# Enable mouse mode for this session
tmux set-option -t "$SESSION_NAME" mouse on

# Split the main window into two vertical layers: top (pane 0) and bottom (pane 1)
tmux split-window -v -t "$SESSION_NAME":0

# === TOP LAYER: Split into three evenly distributed panes ===
# Select pane 0 and split horizontally into two
tmux select-pane -t "$SESSION_NAME":0.0
tmux split-window -h -t "$SESSION_NAME":0.0   # pane 0 (top-left), pane 2 (top-right)

# Split the right pane again to form center + right
tmux select-pane -t "$SESSION_NAME":0.1
tmux split-window -h -t "$SESSION_NAME":0.1   # pane 2 (top-center), pane 3 (top-right)

# === BOTTOM LAYER: Split into two evenly distributed panes ===
tmux select-pane -t "$SESSION_NAME":0.3
tmux split-window -h -t "$SESSION_NAME":0.3   # pane 1 (bottom-left), pane 4 (bottom-right)

# # Apply a tiled layout to improve pane size distribution
# tmux select-layout -t "$SESSION_NAME":0 tiled

# === Pre-fill commands in each pane (without pressing Enter) ===

# Top 3 panes
tmux send-keys -t "$SESSION_NAME":0.0 './launch.sh epc'
tmux send-keys -t "$SESSION_NAME":0.1 './launch.sh enb_zmq'
tmux send-keys -t "$SESSION_NAME":0.2 './launch.sh ue_zmq'

# Bottom 2 panes
tmux send-keys -t "$SESSION_NAME":0.3 'iperf3 -s'
tmux send-keys -t "$SESSION_NAME":0.4 'ip netns exec ue1 iperf3 -c 172.16.0.1 -b 1M -i 1 -t 60'

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
