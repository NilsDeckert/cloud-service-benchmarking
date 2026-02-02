#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Make sure latest state is loaded
source hosts.env

# --- 1. Validation Step ---
# Array of required environment variables
REQUIRED_VARS=(
    "HOST_ACDIS1_IP"
    "HOST_ACDIS2_IP"
    "HOST_ACDIS3_IP"
    "HOST_ACDIS4_IP"
    "HOST_ACDIS5_IP"
)

echo "Checking environment variables..."

# Loop through required variables to check if they are set and not empty
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Environment variable '$var' is missing or empty."
        exit 1
    fi
done

echo "All environment variables present. Starting benchmarks..."
echo "-------------------------------------------------------"

# --- 2. Benchmark Execution Function ---
run_benchmark() {
    local output_name=$1
    local ips=$2

    echo "Running benchmark"
    echo "Target IPs: $ips"
    
    ansible-playbook 03_run_benchmark.yml \
        -i inventory_gcp_compute.yml \
        --vault-password-file pw \
        --extra-vars "target_ip=$ips output_file=$output_name"
    
    echo "Finished $output_name."
    echo "-------------------------------------------------------"
}

create_cluster() {
  local count = $1
}

# --- 3. Execute Scenarios ---

if [[ "$REQUIRED_VARS[0]" != *"ACDIS"* ]]; then
  redis-cli --cluster create $HOST_ACDIS1_IP:7000 $HOST_ACDIS2_IP:7000 $HOST_ACDIS3_IP:7000 $HOST_ACDIS4_IP:7000 $HOST_ACDIS5_IP:7000 --cluster-replicas 0 --cluster-yes
fi

# Scenario: Five Nodes
run_benchmark "acdis_five_nodes" "$HOST_ACDIS1_IP,$HOST_ACDIS2_IP,$HOST_ACDIS3_IP,$HOST_ACDIS4_IP,$HOST_ACDIS5_IP"

#------------------
# Prepare Scanario Four nodes

if [[ "$REQUIRED_VARS[0]" != *"ACDIS"* ]]; then
  # Bring instances to clean state
  for node in ${REQUIRED_VARS[@]}; do
    IP=${!node}
    ssh -o StrictHostKeyChecking=No nils@$IP << 'EOF'
      sudo systemctl stop keydb-cluster
      sudo rm /home/nils/cluster/nodes.conf
      sudo systemctl start keydb-cluster
EOF
  done
else
  # Stop the last node
  ssh -o StrictHostKeyChecking=No nils@$REQUIRED_VARS[-1] "sudo systemctl stop acdis"
  # Restart all others
  for node in "${REQUIRED_VARS[@]:0:4}"; do
    IP=${!node}
    ssh -o StrictHostKeyChecking=No nils@$IP "sudo systemctl restart acdis"
  done
fi

# Shutdown unused node to save money
# ssh -o StrictHostKeyChecking=No nils@$HOST_ACDIS5_IP "sudo poweroff"

# Let cluster boot up
sleep 3

if [[ "$REQUIRED_VARS[0]" != *"ACDIS"* ]]; then
  redis-cli --cluster create $HOST_ACDIS1_IP:7000 $HOST_ACDIS2_IP:7000 $HOST_ACDIS3_IP:7000 $HOST_ACDIS4_IP:7000 --cluster-replicas 0 --cluster-yes
fi

# Scenario: Four Nodes
run_benchmark "acdis_four_nodes" "$HOST_ACDIS1_IP,$HOST_ACDIS2_IP,$HOST_ACDIS3_IP,$HOST_ACDIS4_IP"
#------------------
# Prepare Scenario Three Nodes

if [[ "$REQUIRED_VARS[0]" != *"ACDIS"* ]]; then
  for node in "${REQUIRED_VARS[@]:0:4}"; do
    IP=${!node}
    ssh -o StrictHostKeyChecking=No nils@$IP << 'EOF'
      sudo systemctl stop keydb-cluster
      sudo rm /home/nils/cluster/nodes.conf
      sudo systemctl start keydb-cluster
EOF
  done
else
  ssh -o StrictHostKeyChecking=No nils@$REQUIRED_VARS[-1] "sudo systemctl stop acdis"
  for node in "${REQUIRED_VARS[@]:0:3}"; do
    IP=${!node}
    ssh -o StrictHostKeyChecking=No nils@$IP "sudo systemctl restart acdis"
  done
fi

# Shutdown unused node to save money
# ssh -o StrictHostKeyChecking=No nils@$HOST_ACDIS4_IP "sudo poweroff"

# Let cluster boot up
sleep 3

redis-cli --cluster create $HOST_ACDIS1_IP:7000 $HOST_ACDIS2_IP:7000 $HOST_ACDIS3_IP:7000 --cluster-replicas 0 --cluster-yes

# Scenario: Three Nodes
run_benchmark "acdis_three_nodes" "$HOST_ACDIS1_IP,$HOST_ACDIS2_IP,$HOST_ACDIS3_IP"
#---------------------
# Prepare single node benchmark

if [[ "$REQUIRED_VARS[0]" != *"ACDIS"* ]]; then
  for node in "${REQUIRED_VARS[@]:0:3}"; do
    IP=${!node}
    ssh -o StrictHostKeyChecking=No nils@$IP << 'EOF'
      sudo systemctl stop keydb-cluster
      sudo rm /home/nils/cluster/nodes.conf
      sudo systemctl start keydb-cluster
EOF
  done
else
  ssh -o StrictHostKeyChecking=No nils@$REQUIRED_VARS[1] "sudo systemctl stop acdis"
  ssh -o StrictHostKeyChecking=No nils@$REQUIRED_VARS[2] "sudo systemctl stop acdis"
fi

# Shutdown unused nodes to save money
# ssh -o StrictHostKeyChecking=No nils@$HOST_ACDIS3_IP "sudo poweroff"
# ssh -o StrictHostKeyChecking=No nils@$HOST_ACDIS2_IP "sudo poweroff"

# Let cluster boot up
sleep 3

# Scenario: One Node
run_benchmark "acdis_one_node" "$HOST_ACDIS1_IP"

echo "All benchmarks completed successfully."
