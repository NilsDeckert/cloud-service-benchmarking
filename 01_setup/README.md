# Ansible setup

This directory contains the setup to provision Google Cloud Compute Engine instances that will be used to host the SUTs and the benchmarking code itself.

## Requirements

### Local

To install the necessary ansible packages run:

```bash
ansible-galaxy collection install -r roles/requirements.yml
```

You also have to install some python packages:

```bash
pip install -r requirements.txt
```

Make sure you can execute the `redis-cli` command.
Depending on you Linux Distribution, you might have to install `redis-tools` or `redis`.

### GCP

For authentication, we're using a service account and a downloaded credentials file.
To use these playbooks:
1. Create a service account
2. Create and download a credentials file.
3. Use `ansible-vault encrypt_string --name service_account_contents` and paste the contents of the keyfile.
4. To enable automation, write you vault password to a file named `pwd`
5. Take the encrypted output and paste it into `inventory_gcp_compute.yml`
6. Take the `.json` keyfile and modify it's syntax to `.yml`
7. Paste the `.yml` into an encrypted `group_vars/all/secrets.yml`

Additionally, you have to enable the `Compute Engine API` for the respective project.
Make sure your SSH key is added to your gcp project.


## Preparation

> [!NOTE]
> You might want to do a search and replace to replace `nils` with your username.
> E.g. `sed -i s/nils/myusername/g *`

This project is set up to benchmark four key-value servers in clusters of different sizes.
To configure the program and cluster size to test, edit the `01_create_instances.yml` playbook.
Comment in/out the respective hosts. The configured GCP region enforces a limit of 8 total VMs.

If you want to benchmark a single instance setup, uncomment the "Configure Cluster" tasks in `02_configure_instances.yml`.

By default, the benchmarking instances will send 20 Million requests each. If you want to change that number, edit `03_run_benchmark.yml`.

## Usage

To create the required gcp instances, run the following command:

```bash
ansible-playbook 01_create_instances.yml --ask-vault-pass
```

To configure them, run:

```bash
ansible-playbook 02_configure_instances.yml -i inventory_gcp_compute.yml --ask-vault-pass
```

This step produces a `hosts.env` file that defines environment variables that contain the instances IP addresses. To load the environment variables run:

```bash
source hosts.env
```

You can now either 'manually' benchmark one cluster size or automatically benchmark different cluster sizes.

### Manually

> [!NOTE]
> If you're setting up a cluster, you have to (manually) join all nodes. To do this, run e.g.
> `redis-cli --cluster create $HOST_VALKEY1_IP:7000 $HOST_VALKEY2_IP:7000 $HOST_VALKEY3_IP:7000 --cluster-replicas 0`

You can start the benchmark from the configured benchmark machines:

```bash
ansible-playbook 03_run_benchmark.yml -i inventory_gcp_compute.yml --ask-vault-pass --extra-vars "target_ip=$HOST_VALKEY1_IP,$HOST_VALKEY2_IP,$HOST_VALKEY3_IP output_file=valkey_three_nodes"
```

The recorded histograms will be in `results/bench*/valkey_three_nodes.csv`.

### Automatically

1. Make sure the correct instance names are configured in `execute.sh` by editing the variables in `REQUIRED_VARS`
2. Run the `execute.sh` script
3. The recorded histograms will be in `results/bench*/*.csv`.

---

Finally, you can stop all instances:

```bash
ansible-playbook 04_stop_instances.yml --ask-vault-pass
```
