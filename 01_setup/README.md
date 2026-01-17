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

### GCP

For authentication, we're using a service account and a downloaded credentials file.
To use these playbooks:
1. create a service account
2. create and download a credentials file.
3. Use `ansible-vault encrypt_string --name service_account_contents` and paste the contents of the keyfile.
4. Take the encrypted output and paste it into `inventory_gcp_compute.yml`
5. Take the `.json` keyfile and modify it's syntax to `.yml`
6. Paste the `.yml` into an encrypted `group_vars/all/secrets.yml`

Additionally, you have to enable the `Compute Engine API` for the respective project.

## Usage

To create the required gcp instances, run the following command:

```bash
ansible-playbook 01_create_instance.yml --ask-vault-pass
```

To configure them, run:

```bash
ansible-playbook 02_configure_instances.yml -i inventory_gcp_compute.yml --ask-vault-pass
```

This step produces a `hosts.env` file that defines environment variables that contain the instances IP addresses. To load the environment variables run:

```bash
source hosts.env
```

> [!NOTE]
> If you're setting up a cluster, you have to (manually) join all nodes. To do this, run e.g.
> `redis-cli --cluster create $HOST_VALKEY1_IP:7000 $HOST_VALKEY2_IP:7000 $HOST_VALKEY3_IP:7000 --cluster-replicas 0`

You can start the benchmark from the configured benchmark machines:

```bash
ansible-playbook 03_run_benchmark.yml -i inventory_gcp_compute.yml --ask-vault-pass --extra-vars "target_ip=$HOST_VALKEY_IP"
```

Finally, you can stop all instances:

```bash
ansible-playbook 04_stop_instances.yml --ask-vault-pass
```
