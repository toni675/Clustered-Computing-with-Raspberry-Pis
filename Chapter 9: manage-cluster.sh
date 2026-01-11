#### manage-cluster.sh ####

#!/bin/bash
clear
# === CONFIGURATION ===
SCRIPT_DIR="$HOME/cluster-scripts"  # Update this path if your scripts are stored elsewhere

# === COLOR SETUP ===
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# === MENU DISPLAY FUNCTION ===
print_menu() {
    echo -e "${YELLOW}=== Raspberry Pi Cluster Management ===${RESET}"
    echo "1) Shutdown Cluster"
    echo "2) Reboot Cluster"
    echo "3) Sync Time on Nodes"
    echo "4) Power Report"
    echo "5) Check Connectivity"
    echo "6) Update Cluster"
    echo "7) Uptime Report"
    echo "8) Real-Time CPU Load"
    echo "9) Run MPI Program"
    echo "0) Exit"
    echo
}

# === SCRIPT EXECUTION FUNCTION ===
run_script() {
    local script_name="$1"
    local full_path="$SCRIPT_DIR/$script_name"

    if [[ -x "$full_path" ]]; then
        echo -e "${GREEN}Running: $script_name${RESET}"
        "$full_path"
    else
        echo -e "${RED}Error: $script_name not found or not executable in $SCRIPT_DIR${RESET}"
    fi
}

# === MAIN LOOP ===
while true; do
    print_menu
    read -p "Choose an option [0-9]: " choice
    echo

    case "$choice" in
        1) run_script "shutdown-cluster.sh" ;;
        2) run_script "reboot-cluster.sh" ;;
        3) run_script "sync-nodes-time.sh" ;;
        4) run_script "power_report.sh" ;;
        5) run_script "check-connectivity.sh" ;;
        6) run_script "cluster-update.sh" ;;
        7) run_script "cluster-uptime.sh" ;;
        8) run_script "real-time-load.sh" ;;
        9) run_script "run_mpi_program.sh" ;;
        0) echo -e "${YELLOW}Exiting cluster manager. Goodbye!${RESET}"; break ;;
        *) echo -e "${RED}Invalid choice. Please select 0–9.${RESET}" ;;
    esac
    echo
done
