#!/usr/bin/env bash
set -euo pipefail

CHANNELS=(can_primary can_secondary)
LOG_DIR="/mnt/can_logs"

pids=()
cleanup() {
  for pid in "${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

dump() {
  local ch="$1"
  (
    dir="$LOG_DIR/$ch"
    mkdir -p "$dir"

    ts="$(date -u +'%Y-%m-%dT%H-%M-%SZ')"
    logfile="$dir/${ts}_${ch}.log"

    : > "$logfile"

    echo "[can-log] starting candump on $ch into $logfile"

    exec stdbuf -oL -eL candump -t a "$ch" >>"$logfile" 2>&1
  ) &
  pids+=("$!")
}


main() {
  mkdir -p "$LOG_DIR"
  ls "$LOG_DIR"

  for ch in "${CHANNELS[@]}"; do
    dump "$ch"
  done

  wait
}

main
