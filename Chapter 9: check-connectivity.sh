#### check-connectivity.sh ####

!/bin/bash
clear
# check-connectivity.sh

LOGFILE="cluster_logs/connectivity-$(date '+%Y-%m-%d_%H-%M-%S').log"
mkdir -p cluster_logs

NODES=("2w-node1" "2w-node2" "2w-node3" "2w-node4")

echo "=== Cluster Connectivity Test on $(date) ===" | tee -a "$LOGFILE"

for node in "${NODES[@]}"; do
  echo -n "Pinging $node... " | tee -a "$LOGFILE"
  if ping -c 3 "$node" > /dev/null 2>&1; then
    echo "✔️ Online" | tee -a "$LOGFILE"
  else
    echo "❌ Unreachable" | tee -a "$LOGFILE"
  fi
done
