#!/usr/bin/env bash
set -euo pipefail

CHANNELS=(can_primary can_secondary)
declare -A PIDS
CURR_MP=""

wait_for_mount() {
  local devnode="$1" mp=""
  while :; do
    mp="$(lsblk -no MOUNTPOINT "$devnode" | grep -m1 . || true)"
    [[ -n "$mp" ]] && { echo "$mp"; return; }
    sleep 1
  done
}

init_dump() {
  CURR_MP="$1"
  for ch in "${CHANNELS[@]}"; do
    local dir="$CURR_MP/$ch"
    mkdir -p "$dir"
    echo "[can-log] starting candump on $ch into $dir/"
    (candump -tal "$ch" > "$dir/")
    PIDS[$ch]=$!
  done
}

stop_dump() {
  echo "[can-log] stopping candump process"
  for ch in "${CHANNELS[@]}"; do
    if [[ -n "${PIDS[$ch]:-}" ]]; then
      kill "${PIDS[$ch]}" 2>/dev/null || true
      unset PIDS[$ch]
    fi
  done
  CURR_MP=""
}

echo "[can-log] waiting for usb disk events"

udevadm monitor --udev --subsystem-match=block --property | \
  awk '
    BEGIN { action=""; devname=""; devtype=""; idbus=""; }
    NF==0 {
      if (idbus=="usb" && devtype=="disk" && devname ~ /^\/dev\/sd[a-z]+$/) {
        print action, devname; fflush(stdout);
      }
      action=""; devname=""; devtype=""; idbus="";
      next
    }
    /^ACTION=/  { sub(/^ACTION=/,""); action=$0; next }
    /^DEVNAME=/ { sub(/^DEVNAME=/,""); devname=$0; next }
    /^DEVTYPE=/ { sub(/^DEVTYPE=/,""); devtype=$0; next }
    /^ID_BUS=/  { sub(/^ID_BUS=/,""); idbus=$0; next }
    ' | while read -r ACTION DEVNODE; do
      case "$ACTION" in
        add)
          echo "[can-log] detected $DEVNODE, awaiting mount"
          MP="$(wait_for_mount "$DEVNODE")"
          echo "[can-log] mounted at $MP"
          init_dump "$MP"
          ;;
        remove)
          echo "[can-log] device $DEVNODE removed"
          stop_dump
          ;;
      esac
    done

