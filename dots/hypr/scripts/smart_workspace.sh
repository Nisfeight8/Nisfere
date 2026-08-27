#!/bin/bash

KEY=$1
ACTION=$2
PER_MON=${3:-10}

ACTIVE_MONITOR=$(hyprctl activeworkspace -j | jq -r '.monitor')

INDEX=$(hyprctl monitors -j | jq --arg am "$ACTIVE_MONITOR" -r '
  map(.name) | 
  sort_by((test("^eDP") | not), .) | 
  index($am)
')

if [ -z "$INDEX" ] || [ "$INDEX" = "null" ]; then
    INDEX=0
fi

TARGET=$(( (INDEX * PER_MON) + KEY ))

if [ "$ACTION" = "movetoworkspace" ]; then
    hyprctl dispatch "hl.dsp.window.move({ workspace = '${TARGET}' })"
else
    hyprctl dispatch "hl.dsp.focus({ workspace = '${TARGET}' })"
fi