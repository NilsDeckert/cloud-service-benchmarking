# Analyze

These scripts read in multiple result files for each of the multiple benchmarked services.
To facilitate this, we expect the following data structure:

```text
03_analyze/
├─ redis/
│  ├─ redis1.csv
│  ├─ redis2.csv
│  ├─ redis3.csv
├─ valkey/
│  ├─ valkey1.csv
│  ├─ valkey2.csv
│  ├─ valkey3.csv
├─ keydb/
│  ├─ ....csv
├─ acdis/
│  ├─ ....csv
```
