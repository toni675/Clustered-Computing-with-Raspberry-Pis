#### reboot-cluster.sh ####

#!/bin/bash
clear
# check-health.sh — Monitor temperature, throttling, voltage of host and nodes

LOGFILE="cluster_logs/health-$(date '+%Y-%m-%d-%H-%M-%S').log"
mkdir -p cluster_logs

NODES=("2w-node1" "2w-node2" "2w-node3" "2w-node4")
HOSTNAME=$(hostname)

echo "=== Cluster Health Check on $(date) ===" | tee -a "$LOGFILE"

# Function to explain throttled status
explain_throttled() {
  local HEX="$1"
  local STATUS=$((16#${HEX#0x}))
  local explained=0

  declare -a flags=(
    "0:Currently under-voltage"
    "1:ARM frequency capped"
    "2:Currently throttled"
    "3:Soft temperature limit active"
    "16:Under-voltage occurred since last reboot"
    "17:ARM frequency capping occurred since last reboot"
    "18:Throttling occurred since last reboot"
    "19:Soft temperature limit occurred since last reboot"
  )

  for item in "${flags[@]}"; do
    IFS=":" read -r bit msg <<< "$item"
    if (( STATUS & (1 << bit) )); then
      echo "⚠️  $msg"
      explained=1
    fi
  done

  if [ "$explained" -eq 0 ]; then
    echo "✅ System is healthy — no throttling or under-voltage issues detected."
  fi
}
# Function to run health check on local device
get_health_data() {
  echo "--- $1 ---" | tee -a "$LOGFILE"

  TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2)
  STATUS_HEX=$(vcgencmd get_throttled 2>/dev/null | cut -d'=' -f2)
  VOLT=$(vcgencmd measure_volts 2>/dev/null | cut -d'=' -f2)

  echo "Temperature: $TEMP" | tee -a "$LOGFILE"
  echo "Throttled: $STATUS_HEX" | tee -a "$LOGFILE"
  explain_throttled "$STATUS_HEX" | tee -a "$LOGFILE"
  echo "Voltage: $VOLT" | tee -a "$LOGFILE"
}

# Host health
echo "Checking host ($HOSTNAME)..." | tee -a "$LOGFILE"
get_health_data "$HOSTNAME"

# Node health
for node in "${NODES[@]}"; do
  echo "" | tee -a "$LOGFILE"
  echo "Checking $node..." | tee -a "$LOGFILE"

  if ping -c 1 -W 3 "$node" &>/dev/null; then
    echo "--- $node ---" | tee -a "$LOGFILE"
    ssh "$node" ' 
      echo "Node: $(hostname)"
      TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d"=" -f2)
      STATUS_HEX=$(vcgencmd get_throttled 2>/dev/null | cut -d"=" -f2)
      VOLT=$(vcgencmd measure_volts 2>/dev/null | cut -d"=" -f2)
      echo "Temperature: $TEMP"
      echo "Throttled: $STATUS_HEX"

      HEX="${STATUS_HEX#0x}"
      STATUS=$((16#$HEX))
      explained=0

      flags=(
        "0:Currently under-voltage"
        "1:ARM frequency capped"
        "2:Currently throttled"
        "3:Soft temperature limit active"
        "16:Under-voltage occurred since last reboot"
        "17:ARM frequency capping occurred since last reboot"
        "18:Throttling occurred since last reboot"
        "19:Soft temperature limit occurred since last reboot"
      )

      for item in "${flags[@]}"; do
        IFS=":" read -r bit msg <<< "$item"
        if (( STATUS & (1 << bit) )); then
          echo "⚠️  $msg"
          explained=1
        fi
      done

      if [ "$explained" -eq 0 ]; then
        echo "✅ System is healthy — no throttling or under-voltage issues detected."
      fi

      echo "Voltage: $VOLT"
    ' 2>/dev/null | tee -a "$LOGFILE"
  else
    echo "--- $node ---" | tee -a "$LOGFILE"
    echo "❌ Unreachable or offline." | tee -a "$LOGFILE"
  fi
done
