#!/bin/bash
# Use this if you are only interested in single-node benchmarks
#

source hosts.env

ansible-playbook 03_run_benchmark.yml \
    -i inventory_gcp_compute.yml \
    --vault-password-file pw \
    --extra-vars "target_ip=$HOST_REDIS1_IP output_file=redis_single_node"

ansible-playbook 03_run_benchmark.yml \
    -i inventory_gcp_compute.yml \
    --vault-password-file pw \
    --extra-vars "target_ip=$HOST_VALKEY1_IP output_file=valkey_single_node"

ansible-playbook 03_run_benchmark.yml \
    -i inventory_gcp_compute.yml \
    --vault-password-file pw \
    --extra-vars "target_ip=$HOST_KEYDB1_IP output_file=keydb_single_node"

ansible-playbook 03_run_benchmark.yml \
    -i inventory_gcp_compute.yml \
    --vault-password-file pw \
    --extra-vars "target_ip=$HOST_ACDIS1_IP output_file=acdis_single_node"
