#!/usr/bin/env bash
TYPE="$1"
if [[ "$TYPE" == "sink" ]]; then
  wpctl set-volume @DEFAULT_AUDIO_SINK@ "$2"
elif [[ "$TYPE" == "source" ]]; then
  wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$2"
elif [[ "$TYPE" == "app" ]]; then
  pactl set-sink-input-volume "$2" "$3%"
fi
