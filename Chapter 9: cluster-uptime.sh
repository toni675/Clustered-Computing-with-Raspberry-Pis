#### cluster-uptime.sh ####

#!/bin/bash
clear
# cluster-uptime.sh — Check uptime of all cluster nodes and host

LOGDIR="cluster_logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/uptime-$(date '+%Y-%m-%d_%H-%M-%S').log"

NODES=("3b-host" "2w-node1" "2w-node2" "2w-node3" "2w-node4")

echo "=== Cluster Uptime Check on $(date) ===" | tee -a "$LOGFILE"

for NODE in "${NODES[@]}"; do
    echo "" | tee -a "$LOGFILE"
    echo "--- $NODE ---" | tee -a "$LOGFILE"

    if ping -c 1 -W 2 "$NODE" &>/dev/null; then
        if [ "$(hostname)" = "$NODE" ]; then
            # Local host
            uptime | tee -a "$LOGFILE"
        else
            ssh "$NODE" "hostname; uptime" 2>/dev/null | tee -a "$LOGFILE"
        fi
    else
        echo "❌ $NODE is unreachable or offline." | tee -a "$LOGFILE"
    fi
done
