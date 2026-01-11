#### sync-nodes-time.sh  ####

#!/bin/bash
clear

# sync-nodes-time.sh — Run from host to restart chrony on reachable nodes

# List of known node hostnames (adjust as needed)
NODES=("2w-node1" "2w-node2" "2w-node3" "2w-node4")

RESTART_CMD="sudo systemctl restart chrony"
TIMEOUT=5

echo "[INFO] Starting time synchronization on nodes..."

for NODE in "${NODES[@]}"; do
    echo -n "[INFO] Checking $NODE... "

    if ping -c1 -W$TIMEOUT $NODE &>/dev/null; then
        echo "Reachable. Restarting Chrony..."

        ssh -o ConnectTimeout=$TIMEOUT "$NODE" "$RESTART_CMD" \
            && echo "[SUCCESS] Chrony restarted on $NODE." \
            || echo "[ERROR] SSH command failed for $NODE."
    else
        echo "Unreachable. Skipping."
    fi
done

echo "[INFO] Time sync script completed."
