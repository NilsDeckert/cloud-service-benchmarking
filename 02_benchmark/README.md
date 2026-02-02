# Benchmark

This directory contains the rust code to run the benchmarks. The ansible playbooks deploy the binaries to separate bencher VM instances, but you can run the benchmarks locall as well.

To benchmark a locally running (e.g) redis instance, run

```bash
cargo run
```

You have the following options:
```text
Usage: cargo run -- [OPTIONS]

Options:
  -a, --address <ADDRESS>    Instance address(es) to connect to [default: localhost]
  -p, --port <PORT>          Instance port to connect to [default: 6379]
  -t, --threads <THREADS>    Number of threads to send commands from [default: 16]
  -r, --requests <REQUESTS>  Number of requests to send per client [default: 10000]
  -c, --cmd <CMD>            Type of requests to send [default: etc]
      --cluster              Flag to enable or disable writing result csv
      --skip-logs            Flag to disable writing result csv
  -o, --output <OUTPUT>      Name of the output file [default: histogram]
  -h, --help                 Print help
  -V, --version              Print version
```
