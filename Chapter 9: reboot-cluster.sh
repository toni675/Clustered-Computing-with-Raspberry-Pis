#### reboot-cluster.sh ####

#!/bin/bash
clear

# reboot-cluster.sh — Reboot host or nodes with logging support

LOGDIR="cluster_logs"
LOGFILE="$LOGDIR/reboot-$(date '+%Y-%m-%d_%H-%M-%S').log"
mkdir -p "$LOGDIR"

NODES=("3b-host" "2w-node1" "2w-node2" "2w-node3" "2w-node4")
SELF=$(hostname)
declare -A REBOOT_TIMES
COOLDOWN=20  # seconds

log() {
  echo "$1" | tee -a "$LOGFILE"
}

can_reboot() {
  local node=$1
  local now=$(date +%s)
  local last=${REBOOT_TIMES[$node]:-0}
  if (( now - last < COOLDOWN )); then
    return 1
  fi
  REBOOT_TIMES[$node]=$now
  return 0
}

while true; do
  log "=== Reboot Cluster Utility ==="
  log "Choose an option:"
  log "0) Exit"
  log "1) Reboot ALL nodes"
  for i in "${!NODES[@]}"; do
    log "$((i+2))) Reboot ${NODES[$i]}"
  done

  read -p "Enter your choice: " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 0 && choice <= ${#NODES[@]} + 1 )); then
    if [[ "$choice" -eq 0 ]]; then
      log "Exiting. Bye!"
      sleep 2
      clear
      exit 0

    elif [[ "$choice" -eq 1 ]]; then
      log "Rebooting ALL nodes..."
      for node in "${NODES[@]}"; do
        if ! can_reboot "$node"; then
          clear
          log "⏳ $node is currently rebooting. Please wait a few more seconds."
          echo ""
          continue
        fi
        if ping -c 1 -W 2 "$node" &>/dev/null; then
          if [[ "$node" == "$SELF" ]]; then
            log "Rebooting local host ($node) in 5 seconds..."
            sleep 5
            sudo reboot
          else
            log "Rebooting $node..."
            ssh "$node" "sudo reboot" &>>"$LOGFILE" &
          clear
          fi
        else
          clear
          log "❌ $node is unreachable or offline. Skipping."
          sleep 2
        fi
      done
      wait

    else
      index=$((choice - 2))
      selected="${NODES[$index]}"
      if ! can_reboot "$selected"; then
        clear
        log "⏳ $selected is currently rebooting. Please wait a few more seconds."
        echo ""

        continue
      fi
      if ping -c 1 -W 2 "$selected" &>/dev/null; then
        if [[ "$selected" == "$SELF" ]]; then
          log "Rebooting local host ($selected) in 5 seconds..."
          sleep 5
          sudo reboot
        else
          clear
          log "Rebooting $selected..."
          ssh "$selected" "sudo reboot" &>>"$LOGFILE"
        fi
      else
        clear
        log "❌ $selected is unreachable or offline."
        sleep 2
        
      fi
    fi
  else
     clear
     log "⚠️ Invalid selection. Please try again."
     echo ""
fi

  echo ""
done
