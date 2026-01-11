#### real-time-load.sh ####

#!/bin/bash
# real-time-load.sh

ALL_NODES=("2w-node1" "2w-node2" "2w-node3" "2w-node4")
ONLINE_NODES=()
INTERVAL=5

# Trap Ctrl+C to go back to main cluster manager script
cleanup_and_exit() {
  clear
  echo -e "\n🔁 Returning to Cluster Manager...\n"
  exec ~/manage-cluster.sh
}
trap cleanup_and_exit SIGINT

# Check connectivity
echo -e "\n🔎 Checking connectivity..."
for NODE in "${ALL_NODES[@]}"; do
  if ping -c 1 -W 1 "$NODE" &> /dev/null; then
    echo "✅ $NODE is online"
    ONLINE_NODES+=("$NODE")
  else
    echo "❌ $NODE is unreachable"
  fi
done

if [ ${#ONLINE_NODES[@]} -eq 0 ]; then
  echo "🚫 No nodes online. Exiting."
  exit 1
fi

# Helpers for float comparison
is_greater() {
  awk "BEGIN {exit !($1 > $2)}"
}
is_between() {
  awk "BEGIN {exit !($1 > $2 && $1 <= $3)}"
}

# Live CPU load monitor
echo -e "\n📡 Real-Time Load Heatmap Running. Press Ctrl+C to return."
while true; do
  echo -e "\n=== $(date) ==="
  for NODE in "${ONLINE_NODES[@]}"; do
    LOAD=$(ssh "$NODE" "cut -d ' ' -f1 /proc/loadavg 2>/dev/null")
    if [[ -z "$LOAD" ]]; then
      echo -e "$NODE: \033[1;30mUNKNOWN (SSH error)\033[0m"
      continue
    fi

    COLOR="\033[0;32m"  # green
    if is_greater "$LOAD" "1.5"; then COLOR="\033[0;31m"; fi  # red
    if is_between "$LOAD" "0.8" "1.5"; then COLOR="\033[1;33m"; fi  # yellow

    printf "%-10s: ${COLOR}Load Avg = %s\033[0m\n" "$NODE" "$LOAD"
  done
  sleep "$INTERVAL"
done
