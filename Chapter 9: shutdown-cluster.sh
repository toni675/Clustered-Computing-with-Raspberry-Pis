#### shutdown-cluster.sh ####
#!/bin/bash
clear
# shutdown-cluster.sh — Menu-based shutdown for Raspberry Pi cluster with node check and persistent menu

LOGFILE="cluster_logs/shutdown-$(date '+%Y-%m-%d_%H-%M-%S').log"
mkdir -p cluster_logs

NODES=("2w-node1" "2w-node2" "2w-node3" "2w-node4")
HOSTNAME=$(hostname)

echo "=== Cluster Shutdown Script Started on $(date) ===" | tee -a "$LOGFILE"

function check_and_shutdown_node() {
  local node=$1
  clear
  echo -n "Checking $node... " | tee -a "$LOGFILE"
  if ping -c 1 -W 3 "$node" &>/dev/null; then
    echo "Online. Shutting down..." | tee -a "$LOGFILE"
    ssh "$node" "sudo shutdown now" &>> "$LOGFILE" &
    sleep 8
  else
    echo "Unreachable or already shut down." | tee -a "$LOGFILE"
  fi
}

while true; do
  echo
  echo "========== Shutdown Menu =========="
  echo "0) Exit"
  echo "1) Shutdown the entire cluster (host + all nodes)"
  echo "2) Shutdown specific node(s)"
  echo "==================================="
  read -rp "Choose an option: " option

  case "$option" in
    0)
      echo "Shutdown cancelled. Bye!" | tee -a "$LOGFILE"
      sleep 1
      clear
      exit 0
      ;;
    1)
      echo "Shutting down all nodes..." | tee -a "$LOGFILE"
      for node in "${NODES[@]}"; do
        check_and_shutdown_node "$node"
      done
      echo "Shutting down host ($HOSTNAME) in 10 seconds..." | tee -a "$LOGFILE"
      sleep 10
      sudo shutdown now
      break
      ;;
    2)
      clear
      echo "====== Select Node(s) to Shutdown ======"
      for i in "${!NODES[@]}"; do
        echo "$((i+1))) ${NODES[$i]}"
      done
      echo "5) All nodes"
      echo "0) Exit"
      echo "========================================"
      read -rp "Enter node numbers (e.g., 1 3) or '5' for all: " input

      if [[ "$input" == "0" ]]; then
        clear |  echo "Returning to main menu..." | tee -a "$LOGFILE"
        continue
      elif [[ "$input" == "5" ]]; then
        for node in "${NODES[@]}"; do
          check_and_shutdown_node "$node"
        done
        continue
      else
        for index in $input; do
          if [[ "$index" =~ ^[1-4]$ ]]; then
            node="${NODES[$((index-1))]}"
            check_and_shutdown_node "$node"
          else
            clear
            echo "Invalid node number: $index" | tee -a "$LOGFILE"
          fi
        done
        continue
      fi
      ;;
    *)
      clear
      echo "Invalid option. Try again." | tee -a "$LOGFILE"
      sleep 1
      ;;
  esac
done
