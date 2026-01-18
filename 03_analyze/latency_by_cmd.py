#!/bin/python3

import os
import sys
import glob
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

folders = sys.argv[1:]
dfs = []
for folder in folders:
    service = os.path.dirname(folder)
    files = glob.glob(f"{folder}/*.csv")

    for file in files:
        df = pd.read_csv(file, comment="#")
        df["service"] = service
        df["node"] = file
        dfs.append(df)

df = pd.concat(dfs, ignore_index=True)

print("=== BY SERVICE ===")

print("=== BY NODE ===")
print(df.groupby(["Node"]).describe())
plt.figure(figsize=(10, 6))
sns.boxplot(x="Node", y="latency", data=df)
plt.show()

print("\n=== BY CMD ===")
print(df.groupby(["cmd"])["latency"].describe())
sns.boxplot(x="cmd", y="latency", data=df)
plt.show()
#
#     print()
#     print(df["thread"] + 5)
# print(df.head())
# print()
# print(df.groupby(["cmd"]).mean())

# by_cmd = sns.boxplot(x="cmd", y="latency", data=df)
# by_cmd.set(xlabel="Command", ylabel="Latency")
# plt.show()

# by_thread = sns.boxplot(x="thread", y="latency", data=df)
# plt.show()
