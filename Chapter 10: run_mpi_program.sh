#### run_mpi_program.sh ####

#!/bin/bash

# === Clear screen ===
clear

# === Define MPI program directory ===
PROG_DIR="/mnt/nfs_share/mpi-progs"
mkdir -p "$PROG_DIR"

# === Define host list (including host machine) ===
HOSTS=("3b-host" "2w-node1" "2w-node2" "2w-node3" "2w-node4")

# === Create temporary dynamic hostfile ===
HOSTFILE="/tmp/hostfile_dynamic"
> "$HOSTFILE"

echo "🔎 Checking node connectivity..."
for HOST in "${HOSTS[@]}"; do
    if ping -c 1 -W 1 "$HOST" &> /dev/null; then
        echo "✅ $HOST is online."
        while true; do
            read -p "👉 How many processes do you want to assign to [$HOST] (0-4)? " SLOTS
            if [[ "$SLOTS" =~ ^[0-4]$ ]]; then
                echo "$HOST slots=$SLOTS" >> "$HOSTFILE"
                break
            else
                echo "❌ Invalid input. Please enter a number from 0 to 4."
            fi
        done
    else
        echo "❌ $HOST is offline. Skipping..."
    fi
    echo ""
done

# === Prompt for program name ===
cd "$PROG_DIR"
while true; do
    echo "📁 Available programs in $PROG_DIR:"
    ls
    echo ""
    read -e -p "📦 Enter the name of the MPI program to run: " PROG_NAME
    if [ -f "$PROG_NAME" ]; then
        PROG_PATH="$PROG_DIR/$PROG_NAME"
        break
    else
        echo "🚫 Error: '$PROG_NAME' not found."
    fi
done
cd - > /dev/null

# === Create log file path ===
LOG_BASE_DIR="/mnt/nfs_share/mpi-logs"
LOG_SUBDIR="${LOG_BASE_DIR}/${PROG_NAME}.log"
mkdir -p "$LOG_SUBDIR"

TIMESTAMP=$(date +"%d-%m-%y. %H-%M-%S")
LOG_FILE="${LOG_SUBDIR}/${TIMESTAMP}.log"

# === Run the program with log file path as argument ===
echo ""
echo "🚀 Running $PROG_NAME using mpirun..."
echo "⏱️  Timing execution..."

{
    echo "=== Date ==="
    echo "$(date +"%a %b %d %H:%M:%S %Y")"
    echo ""
    echo "=== Hostfile Used ==="
    cat "$HOSTFILE"
    echo ""
    echo "=== Program Output ==="
    time mpirun --hostfile "$HOSTFILE" "$PROG_PATH" "$LOG_FILE"
} 2>&1 | tee "$LOG_FILE"

echo ""
echo "✅ Program execution complete. Log saved to: $LOG_FILE"

