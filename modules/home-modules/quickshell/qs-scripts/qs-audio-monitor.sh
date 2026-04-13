#!/usr/bin/env bash
emit_state() {
  local out_vol out_muted in_vol in_muted out_desc in_desc apps

  out_vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0.00")
  in_vol=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || echo "Volume: 0.00")

  out_muted="false"
  in_muted="false"
  echo "$out_vol" | grep -q "MUTED" && out_muted="true"
  echo "$in_vol" | grep -q "MUTED" && in_muted="true"

  out_vol_num=$(echo "$out_vol" | grep -oP '[\d.]+' | head -1)
  in_vol_num=$(echo "$in_vol" | grep -oP '[\d.]+' | head -1)

  out_desc=$(pactl get-default-sink 2>/dev/null || echo "")
  in_desc=$(pactl get-default-source 2>/dev/null || echo "")

  apps=$(pactl -f json list sink-inputs 2>/dev/null |
    python3 -c "
import json,sys
try:
  inputs=json.load(sys.stdin)
  result=[]
  for i in inputs:
    idx=i.get('index',0)
    props=i.get('properties',{})
    name=props.get('application.name') or props.get('media.name') or 'Unknown'
    vols=i.get('volume',{})
    vol=int(list(vols.values())[0].get('value_percent','0%').rstrip('%'))/100.0 if vols else 0.0
    result.append({'index':idx,'name':name,'volume':round(vol,3),'muted':i.get('mute',False)})
  print(json.dumps(result))
except:
  print('[]')
" 2>/dev/null || echo "[]")

  printf '{"type":"audio","data":{"output":{"desc":"%s","volume":%s,"muted":%s},"input":{"desc":"%s","volume":%s,"muted":%s},"apps":%s}}\n' \
    "$out_desc" "${out_vol_num:-0}" "$out_muted" \
    "$in_desc" "${in_vol_num:-0}" "$in_muted" \
    "$apps"

  printf '{"type":"mic","muted":%s}\n' "$in_muted"
}

emit_state

pw-mon 2>/dev/null | while read -r line; do
  case "$line" in
  *"added"* | *"removed"* | *"changed"*)
    emit_state
    ;;
  esac
done
