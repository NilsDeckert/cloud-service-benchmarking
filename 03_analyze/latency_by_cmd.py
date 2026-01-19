#!/bin/python3

import os
import sys
import glob
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

folders = sys.argv[1:]
dfs = []

# Collect csv from given folders
for folder in folders:
    service = os.path.dirname(folder)
    files = glob.glob(f"{folder}/*.csv")

    for file in files:
        df = pd.read_csv(file, comment="#")
        df["service"] = service
        df["node"] = file
        # "Explode" csv. Repeat each latency 'count' times.
        df = df.loc[df.index.repeat(df['count'])]
        print(f"{file} has {len(df)} entries")

        dfs.append(df)

# Combine all dataframe into one
df = pd.concat(dfs, ignore_index=True)

print("=== BY SERVICE ===")
plt.figure(figsize=(10, 6))
sns.boxplot(x="service", y="latency", data=df)
plt.show()

print("=== BY NODE ===")
print(df.groupby(["node"]).describe())
plt.figure(figsize=(10, 6))
sns.boxplot(x="node", y="latency", data=df)
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
