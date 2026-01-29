#!/bin/python3

import os
import sys
import glob
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

folders = sys.argv[1:]
output = "images/" + folders[0].split("/")[0]

# If the output folder does not exist, create it
if not os.path.exists(output):
    os.makedirs(output)

dfs = []

# Collect csv from given folders
for folder in folders:
    service = folder.rstrip("/").split("/")[-1]
    service.rstrip(".csv")
    print(f"Service: {service}")
    files = glob.glob(f"{folder}/*.csv")

    service_list = []

    for file in files:
        df = pd.read_csv(file, comment="#")
        df["service"] = service
        df["node"] = os.path.basename(file).rstrip(".csv")
        # "Explode" csv. Repeat each latency 'count' times.
        df = df.loc[df.index.repeat(df['count'])]
        print(f"{file} has {len(df)} entries")

        service_list.append(df)

    df = pd.concat(service_list, ignore_index=True)
    dfs.append(df)

    ### Put analysis per project here
    plt.figure(figsize=(10, 6))
    boxplot = sns.boxplot(x="cmd", y="latency", data=df, showfliers=False)
    boxplot.set_title(f"Latency by command {service}")
    plt.savefig(f"{output}/{service}_latency_by_command.png")
    plt.close()

# Combine all dataframe into one
df = pd.concat(dfs, ignore_index=True)
print(df.head())

print("=== BY SERVICE ===")
plt.figure(figsize=(10, 6))
summary = sns.boxplot(x="service", y="latency", data=df, showfliers=False)
summary.set_title("Combined latency per service")
plt.savefig(f"{output}/summary_latency.png")
plt.close()

print("=== BY BENCHER ===")
print(df.groupby(["node"]).describe())
plt.figure(figsize=(10, 6))
validation = sns.boxplot(x="node", y="latency", data=df, showfliers=False)
plt.savefig(f"{output}/validation_bencher.png")
plt.close()

# print("\n=== BY CMD ===")
# print(df.groupby(["cmd"])["latency"].describe())
# sns.boxplot(x="cmd", y="latency", data=df, showfliers=False)
# plt.show()

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
