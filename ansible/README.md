# Ansible setup

This directory contains the setup to provision Google Cloud Computeengine instances that will be used to host the SUTs and the benchmarking code itself.

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

For authentication, we're using a service account and a downloaded credentials file. To use these playbooks, create a service account, create a credentials file and paste the contents of the credential `.json` into an encrypted `group_vars/all/secrets.yml`, modifying the json syntax to `.yml`.

Additionally, you have to enable the `Compute Engine API` for the respective project.

## Usage

To create the required gcp instances, run the following command:

```bash
ansible-playbook --ask-vault-pass create_instance.yml
```
