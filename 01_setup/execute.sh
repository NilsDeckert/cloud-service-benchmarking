#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Make sure latest state is loaded
source hosts.env

# --- 1. Validation Step ---
# Array of required environment variables
REQUIRED_VARS=(
    "HOST_KEYDB1_IP"
    "HOST_KEYDB2_IP"
    "HOST_KEYDB3_IP"
    "HOST_KEYDB4_IP"
    "HOST_KEYDB5_IP"
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

redis-cli --cluster create $HOST_KEYDB1_IP:7000 $HOST_KEYDB2_IP:7000 $HOST_KEYDB3_IP:7000 $HOST_KEYDB4_IP:7000 $HOST_KEYDB5_IP:7000 --cluster-replicas 0 --cluster-yes

# Scenario: Five Nodes
run_benchmark "keydb_five_nodes" "$HOST_KEYDB1_IP,$HOST_KEYDB2_IP,$HOST_KEYDB3_IP,$HOST_KEYDB4_IP,$HOST_KEYDB5_IP"

for node in ${REQUIRED_VARS[@]}; do
  IP=${!node}
  ssh -o StrictHostKeyChecking=No nils@$IP << 'EOF'
    sudo systemctl stop keydb-cluster
    sudo rm /home/nils/cluster/nodes.conf
    sudo systemctl start keydb-cluster
EOF
done

# Shutdown unused node to save money
# ssh -o StrictHostKeyChecking=No nils@$HOST_KEYDB5_IP "sudo poweroff"

# Let cluster boot up
sleep 3

redis-cli --cluster create $HOST_KEYDB1_IP:7000 $HOST_KEYDB2_IP:7000 $HOST_KEYDB3_IP:7000 $HOST_KEYDB4_IP:7000 --cluster-replicas 0 --cluster-yes

# Scenario: Four Nodes
run_benchmark "keydb_four_nodes" "$HOST_KEYDB1_IP,$HOST_KEYDB2_IP,$HOST_KEYDB3_IP,$HOST_KEYDB4_IP"

for node in "${REQUIRED_VARS[@]:0:4}"; do
  IP=${!node}
  ssh -o StrictHostKeyChecking=No nils@$IP << 'EOF'
    sudo systemctl stop keydb-cluster
    sudo rm /home/nils/cluster/nodes.conf
    sudo systemctl start keydb-cluster
EOF
done

# Shutdown unused node to save money
# ssh -o StrictHostKeyChecking=No nils@$HOST_KEYDB4_IP "sudo poweroff"

# Let cluster boot up
sleep 3

redis-cli --cluster create $HOST_KEYDB1_IP:7000 $HOST_KEYDB2_IP:7000 $HOST_KEYDB3_IP:7000 --cluster-replicas 0 --cluster-yes

# Scenario: Three Nodes
run_benchmark "keydb_three_nodes" "$HOST_KEYDB1_IP,$HOST_KEYDB2_IP,$HOST_KEYDB3_IP"

for node in "${REQUIRED_VARS[@]:0:4}"; do
  IP=${!node}
  ssh -o StrictHostKeyChecking=No nils@$IP << 'EOF'
    sudo systemctl stop keydb-cluster
    sudo rm /home/nils/cluster/nodes.conf
    sudo systemctl start keydb-server
EOF
done

# Shutdown unused nodes to save money
# ssh -o StrictHostKeyChecking=No nils@$HOST_KEYDB3_IP "sudo poweroff"
# ssh -o StrictHostKeyChecking=No nils@$HOST_KEYDB2_IP "sudo poweroff"

# Let cluster boot up
sleep 3

# Scenario: One Node
run_benchmark "keydb_one_node" "$HOST_KEYDB1_IP"

echo "All benchmarks completed successfully."
