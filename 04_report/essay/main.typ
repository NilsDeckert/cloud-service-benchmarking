#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Latency comparison of key-value stores for different cluster sizes],
  abstract: [
    In-memory key-value stores are a common building block in modern server systems, often leveraged as a cache to reduce latency for clients.
    In this study we benchmark the four open-source in-memory key-value-stores Redis, Valkey, KeyDB, and Acdis and compare their latency for clusters of different sizes.
    We find that Redis features the lowest latency for single-node setups, but has the highest latency of the compared alternatives for all multi-node setups.
    For clusters, the tested applications have comparable latencies, with KeyDB exhibiting the lowest latency for three and four nodes and Valkey having the lowest latency for the tested five node setups.
    For the tested workload of 60 Million Requests, only minor improvements in latency were observed for clusters larger than three nodes.
  ],
  authors: (
    (
      name: "Nils Deckert",
      // department: [Co-Founder],
      organization: [Technische Universität Berlin],
      location: [Berlin, Germany],
      email: "deckert@campus.tu-berlin.de"
    ),
  ),
  // index-terms: ("Scientific writing", "Typesetting", "Document creation", "Syntax"),
  bibliography: bibliography("refs.bib"),
  figure-supplement: [Fig.],
)

#set text(
  font: "Times New Roman",
  size: 10pt
)

// Introduction, Methods, Results and Discussion
= Introduction

Key-Value stores are a common part of modern online systems.
Especially for low-latency systems, in-memory databases allow for faster data accesses than traditional, disk-based applications @rosenscholdNextGenerationCloudnative2025.
The most prominent example is Redis #footnote[https://redis.io] @akhtarPopularityRankingDatabase2023a @DBEnginesRankingPopularity2026, which is often used for caching @yangLargescaleAnalysisHundreds2021 @HowStackOverflow2019.
Caused by a change of license in #cite(<redisRedisAdoptsDual>, form: "year"), multiple open source alternatives emerged. Valkey #footnote[https://valkey.io] and KeyDB #footnote[https://docs.keydb.dev] are forks of the original Redis project which claim to be faster drop-in alternatives. Acdis #footnote[https://github.com/NilsDeckert/acdis] is a case study of the actor model, implementing a minimal redis-compatible application.

#linebreak()

This paper aims to provide a comparison between the four open-source key-value stores Redis, Valkey, KeyDB and Acids. As the main metric for this comparison, we will focus on latency. To assess their capabilities in multiple settings, we will benchmark the systems in both single-node and cluster deployments of different sizes.

= Systems Under Test

== Background

In 2014, Redis was the most-popular key-value store.
In #cite(<redisRedisAdoptsDual>, form: "year"), the license was changed to closed source. This prompted multiple initiatives to fork the key-value store and continue on their own under open-source licenses.
The most-popular of these forks is Valkey, which is now backed by the Linux foundation, which in turn is backed by Google, Meta and Microsoft amongst others.
KeyDB is another fork that claims to be a faster drop-in replacement to Redis. KeyDB is owned by Snap Inc., the company behind Snapchat.

== Benchmark Objectives

Redis, Valkey and KeyDB share a large part of their codebase, which could suggest similar performance characteristics to users.
At the same time, KeyDB claims to be "a faster drop in alternative to Redis" @KeyDBFasterRedisa.
Acdis is an entirely different approach, implementing a key-value store based on the Actor Model to leverage parallel processing for faster operations.
With this study, we want to (a) examine KeyDBs claim and (b) provide users with the necessary data to choose a software solution for their deployment use cases.

// Methods

= Benchmark Design

With our benchmarks we want to give meaningful comparisons of the tested system's latency for the operation in real-world conditions.
For this, @Sec_Hardware will detail the execution environment under which the benchmarks were conducted.
Afterwards, @Sec_SystemSetup will explain the tested systems and cluster setups, as well as their respective configurations.
Finally, @Sec_LoadGeneration will deep-dive into the data generation chosen to provide realistic usage data.

== Hardware<Sec_Hardware>

In order to provide a realistic execution environment for our benchmark, it is important to deploy the systems under test to production ready machines on the internet.
Testing these systems locally and running all cluster nodes on the same machine would neglect how these systems are used in the real world.
The latency and error-proneness of network connections are an important factor in the real life operation of IT systems.

In the European Union, around 45% of enterprises utilize cloud computing services in their businesses @CloudComputingStatistics. Another 45% of them are using these services to host database systems @CloudComputingStatistics.

To recreate conditions that come close to that of real-world operations, we decided the deploy both the systems under tests and the load generators to virtual machines on the Google Compute Engine.
Both the key-value stores and the benchmarking software were deployed to `n4-standard-highcpu` virtual machines.

#figure(
  caption: "Specs of the n4-standard-highcpu Virtual Machine"
)[
#table(
    columns: (auto, auto),
  )[*Spec*][*Value*][
    vCPUs][4][
    Memory][8 GB][
    Default egress bandwith][Up to 10 Gbps]
]

The virtual machines were deployed to the `europe-north2-a` region (Stockholm) due to higher CPU usage quotas compared to other european regions. Both the SUTs and the load generators were deployed to the same region.

== System Setup<Sec_SystemSetup>

In order to provide an accurate assessment for the latency of the tested systems, we examine the systems under various constellations: \ \

- Single Node
- Cluster of three nodes
- Cluster of four nodes
- Cluster of five nodes
\ 

The minimum cluster size for Redis and its derivatives is three, hence we were not able to conduct benchmarks with two nodes.
The upper bound of the tested cluster sizes was dictated by the enforced CPU quotas of the Google Compute Engine.

The requests sent to the systems under test are coming from three separate Google Compute Engine virtual machines. The generation of the benchmarking data is detailed in @Sec_LoadGeneration.
To assess how additional nodes help the cluster to cope with demand, we kept the same number of load generators while varying the size of the SUT cluster. \ \

The virtual machines hosting the Redis, Valkey and Acdis applications, as well as the load generators were running Ubuntu 24.04. Since there was no KeyDB release available for that Ubuntu version, we used Ubuntu 22.04 for this SUT.

In order to reduce the number of variable factors in the benchmarks and to create fair conditions for all SUTs, we disabled replication, snapshots and persistence for Redis, Valkey and KeyDB. Acdis does not support any of these features, so we kept the default configuration.

Additionally, we followed the vendors recommendations for configuration and set the number of usable CPU cores for the Redis forks to 3 (number of CPU cores - 1).

== Load Generation<Sec_LoadGeneration>

In order to generate meaningful results, we need to subject the application to a realistic usage scenario.
#cite(<atikogluWorkloadAnalysisLargeScale2012>, form: "author") collected traces on the memcached cluster used at Facebook in #cite(<atikogluWorkloadAnalysisLargeScale2012>, form: "year"). The collected traces include 284 billion requests over the span of 'several days'.
A similar study was conducted by researchers at Twitter in #cite(<yangLargescaleAnalysisHundreds2021>, form: "year") @yangLargescaleAnalysisHundreds2021. In this case, the researches analyzed the data of about 700 billion requests 153 Twemcache instances.

In their study, Atikoglu et al. analyzed the workloads from five memcached pools serving different purposes @atikogluWorkloadAnalysisLargeScale2012, namely:

 - User-account status info
 - Object metadata
 - Browser information
 - System data on service location
 - General-Purpose

Based on the traces collected for the general-purpose pool, the researches provide a model to recreate realistic usage behavior for key-value stores. We will base the design of our load generator on this model.

The described model suggests a 70% / 25% / 5% ratio 
#footnote[Approximate values, the paper only shows a barchart without providing concrete numbers.]
of the received GET / DEL / SET requests.
In the study of Twemcache deployments at Twitter, the ratios differ from those examined at Facebook @atikogluWorkloadAnalysisLargeScale2012. While GET and SET operations are still the most commenly used, #cite(<yangLargescaleAnalysisHundreds2021>, form: "author") observed a noticeably higher average percentage of GET requests of around \~90%.
  Still, around a third of the clusters are considered 'write-heavy' ($gt.eq 35%$ write operations).
\ \

In addition to the ratio of received commands, @atikogluWorkloadAnalysisLargeScale2012 provides distributions for key and value lengths.
Both @atikogluWorkloadAnalysisLargeScale2012 and @yangLargescaleAnalysisHundreds2021 observe, that the majority of both key and value sizes are relatively small. The model described in @atikogluWorkloadAnalysisLargeScale2012 uses a Generalized Extrem Value distribution with parameters $mu = 30.7984, alpha = 8.20449, k = 0.078688$ for key sizes. A visualization of the distribution is shown in @fig_key_size_distribution.

#figure(
  caption: [The distribution of key sizes used for the benchmark as described in @atikogluWorkloadAnalysisLargeScale2012]
)[
  #image("./graph_code/etc_key_size.png")
]<fig_key_size_distribution>

For value sizes of 15 bytes and larger, a Generalized Pareto distribution with parameters $θ = 0, σ = 214.476, k = 0.348238$ is chosen.
The first 15 values and their respective probabilties are given in @table_val_size_probs. The combined distribution is visualized in @fig_val_size_distribution.
Both distributions provide a realistic representation of object sizes, independet of temporal patterns.

#figure(
  caption: [The distribution of value sizes used for the benchmark as described in @atikogluWorkloadAnalysisLargeScale2012]
)[
  #image("./graph_code/etc_value_size.png")
]<fig_val_size_distribution>

#figure(
  caption: [Probabilities for the first 15 value sizes, as given in @atikogluWorkloadAnalysisLargeScale2012]
)[
#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  table(
    columns: (auto, auto),
    inset: 8pt,
    [*Value size*], [*Probability*],
    [0], [0.00536],
    [1], [0.00047],
    [2], [0.17820],
    [3], [0.09239],
    [4], [0.00018],
    [5], [0.02740],
    [6], [0.00065],
    [7], [0.00606],
  ),
  
  // Second half of the table
  table(
    columns: (auto, auto),
    inset: 8pt,
    [*Value size*], [*Probability*],
    [8], [0.00023],
    [9], [0.00837],
    [10], [0.00837],
    [11], [0.08989],
    [12], [0.00092],
    [13], [0.00326],
    [14], [0.01980],
  )
)
]<table_val_size_probs>

In addition to SET/GET/DEL ratios and request sizes, the two studies @atikogluWorkloadAnalysisLargeScale2012 @yangLargescaleAnalysisHundreds2021 provide data on the timings between consecutive incoming requests and the 'popularity' of single keys.
For simplicity, these factors are not considered in our distributed load-balancing setup. \ \

As described in @Sec_SystemSetup, the benchmarking requests will be sent from three nodes, each running the load generator described here.
Before the benchmark, the load generators will run a warm-up sequence, sending a total of 6 million `SET` requests to the system under test.
For the actual benchmark, the cluster is exposed to a total of 60 million requests with the ratio described above.
Each load generation node is connecting to the SUT with 32 clients.

// Results
= Results <Sec_Results>

After describing the benchmarking setup in @Sec_SystemSetup and the load generation in @Sec_LoadGeneration, this Section will present the collected data for Redis, Valkey and KeyDB.
For Acdis, the load generation led to excessive memory usage which ultimately killed the application.
The results presented here and the behaviour of Acdis will be discussed in @Sec_Discussion. \ \

For the three tested Redis forks, the latencies of the commands behaved similarly throughout the benchmarked cluster sizes.
For all SUTs, the `SET` command had the highest median latency of all tested commands.
Except for the Valkey and KeyDB single node deployments, the `GET` command consistenly was the fastest of the three request types.
For these two exceptions, both `DEL` and `GET` exhibited the same latency. @fig_relative_cmd_latency shows the relative latency of the `GET` and `DEL` commands compared to the latency of the `SET` command.
While both Valkey and KeyDB showed an increasing descrepancy in latency between the `SET` command and the `DEL` and `GET` commands for growing clusters, this behaviour could not be observed for Redis.
In this case, the difference between `SET` and the other commands decreased in the five node cluster compared to the four node deployment.\ \

#figure(
  image("./images/cmd_latency_variance.png", width: 100%),
  caption: [Relative latency of `DEL` and `GET` commands relative to `SET`],
  placement: auto,
  scope: "parent",
) <fig_relative_cmd_latency>

Regarding the median latencies of the tested applications for varying cluster sizes, we observe that the measured latency decreases with increasing cluster size for all SUTs.
While the trend was the same for all of the three applications, the rate with which the latency decreased varies accross SUTs.
@fig_summary_median_latencies shows the measured command latencies for Redis, Valkey and KeyDB.

#figure(
  caption: "Summary of the median latencies of the SUTs"
)[
  #image("./images/barchart_latency.png")
] <fig_summary_median_latencies>

For single node setups, the difference in median latency across the tested applications is very noticeable.
Valkey has the highest median latency at $371 mu s$, KeyDB follows at $321 mu s$ and Redis has the lowest median latency for single-node setups at $299 mu s$.

Once additional nodes are added to the cluster however, the benchmark results show a change in the overall standings.
For three, four and five node clusters, Redis shows the highest recorded latency of the three alternatives. \ \

Looking at the frequency of recorded latencies, we observe multiple peaks for Valkey and KeyDB single-node deployments. These peaks are not present for Redis or any multi-node deployments. @fig_latency_freq_redis and @fig_latency_freq_valkey show a comparison between the single-node deployments of Redis and Valkey.

#figure(
  caption: "Frequencies of recorded latencies for a single node Redis deployment"
)[
  #image("./images/1-nodes/redis_latency_frequency.png")
] <fig_latency_freq_redis>

#figure(
  caption: "Frequencies of recorded latencies for a single node Valkey deployment. Note the three distinct peaks."
)[
  #image("./images/1-nodes/valkey_latency_frequency.png")
] <fig_latency_freq_valkey>

== Acdis

When running the benchmarks against Acdis, we faced issues that 
 the benchmarks did not run to completion, as the application was stopped by the OS during the run.

After investigation we found that the memory usage of Acdis was considerably higher than that of the Redis derivatives.
Before the end of the benchmark, the application attempted to reserve more memory than was available for the Virtual Machine.
As a result the operating system stopped the SUT early with an "out-of memory" exception.
@fig_gcp_memory_glibc shows the memory consumption for a three node Acdis deployment as recorded by the Google Compute Engine.

#figure(
  caption: "Memory usage for a three node Acdis deployment. Note that the tails after the drop are artificially extended for better readability of the graph." 
)[
  #image("./images/GCP_Memory_glibc.png")
] <fig_gcp_memory_glibc>

To further investigate the memory usage of Acdis, we exchanged the default glibc memory allocator to tikv-jemalloc, which is also used by Redis (*CITATION NEEDED*).
However, that did not change the behaviour significantly reaching the highest memory usage at $94.7%$ instead of $95.65$.
As 25% of requests are `DEL` requests, we modified the Acdis source code to shrink the underlying HashMap to the minimum size for every received `DEL` request.
Again, this did not change the memory usage significantly, leading to the process being killed at $90.8%$ usage.

// Discussion
= Discussion <Sec_Discussion>

Throughout all applications and all cluster sizes, the `SET` command had the highest latency of the three tested commands.
This is in line with expected behaviour of the equivalent HashMap operations.
While the theoretical time complexity of the three operations is `O(1)`, adding keys is highly expensive in practice.
It involves allocating memory for the value itself and the respective metadata and thus adds an expensive overhead.

Since we did not consider the popularity of single keys and did not differentiate between cache hits and cache misses, the load generator sent requests for keys without considering if the cluster had seen them or not.
This most likely resulted in numerous `GET` requests for keys that the cluster hadn't seen before.
In addition to the already great performance of the `GET` operation, the system can avoid sending data over the network in these cases, reducing the measured latency even more.

Since the `SET` and `DEL` operations return output independet of the value length, our ommission likely skewed the results for the `GET` command, which returns the entire value of the given key. \ \

A noticeable difference between the single-node and multi-node benchmarks is the order of the fastest SUTs.
While Redis had the lowest latency of all applications for a single node, it had the highest latency in all other multi-node runs.
Thus, if users do not intend to scale their deployments horizontally, Redis likely is the most promising choice among the tested applications.

In our benchmarks, KeyDB was the fastest SUT for clusters of three and four nodes. For one and five-node deployments however, their claim to be "a faster drop in alternative to Redis" @KeyDBFasterRedisa did not hold true.
Based on the data we collected, KeyDB is the fastest choice for small clusters.
For our five-node benchmark, Valkey had the lowest latency.
As our study only benchmarked clusters of up to five nodes however, it is hard to make assumptions about the performance with larger clusters.

As the performance for clusters is ultimately very similar across applications, users should also keep in mind licensing implications.
While Redis changed their licensing model from the SSPL license to the AGPLv3 in 2025 @redisRedisNowAvailable, history has shown that licenses can be changed at the discretion of the maintaining company @redisRedisAdoptsDual.
While Redis and KeyDB are maintained by their respective companies, Valkey is backed by the Linux Foundation #footnote[https://www.linuxfoundation.org/] which ensures the project will stay open-source @Valkeya.

= Conclusion

In this study, we performent benchmarks on the in-memory key-value stores Redis, Valkey, KeyDB and Acdis to assess their latency for increasing cluster sizes.
We found that Redis had the lowest latency for single-node setups but had the highest latency once if was deployed as a cluster.
For three and four node clusters, KeyDB was the fastest of the tested applications. Valkey had the lowest latency for five-node clusters.
For Acdis, the memory usage was substantially higher than that of all other systems under test. This large memory footprint led to early termination of the benchmarks, preventing the collection of meaningful data.

= Outlook

An important limitation of the benchmarking methodology for this study was the omission of key hit-rates, especially for `GET` requests. In order to provide more meaningful results, it would make sense to repeat the benchmarks described here, with a mechanism to to enforce a given hit-rate.

Similarly, future work could repeat the experiments while scaling the workload with the cluster size. In this study we maintain a fixed number of requests to assess the performance improvements of adding nodes to a cluster. Since the improvements where minimal once a cluster size of three nodes was reached, scaling the number of requests could offer additional insights into the performance of the systems under test. \ \

Additionally, we were not able to collect relevant data on the performance of Acdis.
The high memory consumption in comparison to Redis and its derivatives suggest room for optimizations in the implementation of the data storage of the application. Future work could experiment with different HashMap implementations or other similar data structures and investigate their memory footprint.
