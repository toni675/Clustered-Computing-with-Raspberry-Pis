#### cluster-update.sh ####

#!/bin/bash
clear

# cluster-update.sh — Update specific system in the cluster with menu

LOGDIR="cluster_logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/update-$(date '+%Y-%m-%d_%H-%M-%S').log"

HOST="3b-host"
NODES=("2w-node1" "2w-node2" "2w-node3" "2w-node4")

systems=("$HOST" "${NODES[@]}" "Exit")

# Check internet connectivity
echo "Checking internet connection (pinging google.com)..." | tee -a "$LOGFILE"
if ! ping -c 1 -W 3 google.com &>/dev/null; then
    echo "❌ No internet connection detected. Please check your network and try again." | tee -a "$LOGFILE"
    exit 1
else
    echo "✅ Internet connection detected. Proceeding with update..." | tee -a "$LOGFILE"
fi

while true; do
    echo ""
    echo "Select a system to update:" | tee -a "$LOGFILE"
    for i in "${!systems[@]}"; do
        printf "%d) %s\n" $((i + 1)) "${systems[$i]}" | tee -a "$LOGFILE"
    done

    read -rp "Enter your choice [1-${#systems[@]}]: " choice
    echo "" | tee -a "$LOGFILE"

    if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && (( choice >= 1 && choice <= ${#systems[@]} )); then
        selected="${systems[$((choice - 1))]}"
        [[ "$selected" == "Exit" ]] && echo "Exiting." | tee -a "$LOGFILE" | clear && break

        echo "--- Updating $selected ---" | tee -a "$LOGFILE"

        if [[ "$selected" == "$HOST" ]]; then
            sudo apt-get update | tee -a "$LOGFILE"
            read -rp "Do you want to upgrade $HOST? [y/n]: " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y | tee -a "$LOGFILE"
            else
                echo "Upgrade skipped." | tee -a "$LOGFILE"
            fi
        else
            if ping -c 1 -W 2 "$selected" &>/dev/null; then
                ssh "$selected" "sudo apt-get update" | tee -a "$LOGFILE"
                read -rp "Do you want to upgrade $selected? [y/n]: " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    ssh "$selected" "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y" | tee -a "$LOGFILE"
                else
                    echo "Upgrade skipped." | tee -a "$LOGFILE"
                fi
            else
                echo "❌ $selected is unreachable. Attempting to ping..." | tee -a "$LOGFILE"
                ping -c 1 -W 3 "$selected" &>/dev/null && \
                    echo "⚠️  $selected ping responded but SSH failed." | tee -a "$LOGFILE" || \
                    echo "❌ $selected is offline or not responding." | tee -a "$LOGFILE"
            fi
        fi
    else
        echo "Invalid selection. Please try again." | tee -a "$LOGFILE"
    fi
done
 
