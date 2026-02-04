# Analyze

The data analysis is done in the `analyze.ipynb` Jupyter Notebook.

These scripts read in multiple result files for each of the multiple benchmarked services.
To facilitate this, we expect the following data structure:

```text
03_analyze/
├─ five-nodes/
│  ├─ redis/
│  │  ├─ bench1.csv
│  │  ├─ bench2.csv
│  │  ├─ bench3.csv
│  ├─ valkey/
│  │  ├─ bench1.csv
│  │  ├─ bench2.csv
│  │  ├─ bench3.csv
│  ├─ ...
│
├─ four-nodes/
```
