#!/bin/python3

import os
import sys
import glob
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

folders = sys.argv[1:]
output = "images/" + folders[0].split("/")[0]

# If the output folder does not exist, create it
if not os.path.exists(output):
    os.makedirs(output)

dfs = []

def get_weighted_stats(group_df, val_col="latency", weight_col="count"):
    """
    Calculates weighted boxplot statistics (min, q1, median, q3, max)
    Assumes group_df is already sorted by val_col if not done previously.
    """
    d = group_df.sort_values(val_col)
    data = d[val_col]
    weights = d[weight_col]

    cumsum = weights.cumsum()
    cutoff = cumsum / cumsum.iloc[-1]

    # function to find value at specific percentile
    def get_quantile(q):
        # searchsorted finds the index where the cumulative weight passes the quantile
        idx = np.searchsorted(cutoff, q)
        return data.iloc[idx]

    return {
        "med": get_quantile(0.5),
        "q1": get_quantile(0.25),
        "q3": get_quantile(0.75),
        "whislo": data.min(),  # 0th percentile
        "whishi": data.max()   # 100th percentile
    }

percentiles = {}

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
        # df = df.loc[df.index.repeat(df['count'])]
        # print(f"{file} has {len(df)} entries")

        service_list.append(df)

    full_df = pd.concat(service_list, ignore_index=True)
    
    ### Analysis per project
    stats_list = []
    
    # Group by command to calculate stats for each box
    # If you have multiple services/nodes, you might group by ["cmd", "service"] etc.
    groups = full_df.groupby("cmd")
    for name, group in groups:
            # Calculate stats without exploding
            stats = get_weighted_stats(group, val_col="latency", weight_col="count")
            stats["label"] = name # The X-axis label
            stats_list.append(stats)

    # Plotting using bxp (Boxplot from pre-calculated stats)
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # bxp takes a list of dictionaries
    ax.bxp(stats_list, showfliers=False) 
    
    ax.set_title(f"Latency by command {service}")
    ax.set_xlabel("cmd")
    ax.set_ylabel("latency")
    
    plt.savefig(f"images/{service}_latency_by_command.png")
    plt.close()

    # df = pd.concat(service_list, ignore_index=True)
    # dfs.append(df)
    #
    # data = {
    #         "whislo": df["latency"].min()
    #         "q1": 
    #         }
    #
    # ### Put analysis per project here
    # plt.figure(figsize=(10, 6))
    # boxplot = sns.boxplot(x="cmd", y="latency", data=df, showfliers=False)
    # boxplot.set_title(f"Latency by command {service}")
    # plt.savefig(f"images/{service}_latency_by_command.png")
    # plt.close()

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
