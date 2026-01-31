# Cloud Service Benchmarking

[Redis](https://github.com/redis/redis) is a key-value store commonly used in the industry.
Apart from Redis, there are multiple Redis-compatible alternatives like [Valkey](https://valkey.io/), [KeyDB](https://keydb.dev/) or [Acdis](https://github.com/NilsDeckert/acdis) that claim better performance.

This repository contains setups to deploy the respective software projects to the Google Cloud Platform and to benchmark each of them to compare the alternatives. This project is part of the "Cloud Service Benchmarking" course and is following up on the "Future Work" section of the bachelor thesis developing [Acdis](https://github.com/NilsDeckert/acdis).

| Directory | Description |
|-----------|-------------|
| [01_setup/](https://github.com/NilsDeckert/cloud-service-benchmarking/tree/main/01_setup) | Ansible playbooks to setup VMs and orchestrate the benchmark |
| [02_benchmark/](https://github.com/NilsDeckert/cloud-service-benchmarking/tree/main/02_benchmark) | The rust benchmarking code |
| [03_analyze/](https://github.com/NilsDeckert/cloud-service-benchmarking/tree/main/03_analyze) | Python code to generate plots |
| [04_report/](https://github.com/NilsDeckert/cloud-service-benchmarking/tree/main/04_report) | Typst code for final presentation and written report |
