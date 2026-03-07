#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Latency comparison of key-value stores for different cluster sizes],
  abstract: [
    We've benchmarked the open source key-value stores Redis, Valkey, KeyDB and Acdis for different cluster sizes. We found that XXX features the lowest latency for single-node setups, while YYY is faster for clusters of up to 7 nodes. For clusters of 8 nodes and up, ZZZ is the fastest alternative.
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
KeyDB is another fork that claims to be a faster drop-in replacement to Redis. KeyDB is own by Snap Inc., the company behind Snapchat.

== Benchmark Objectives

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
Except for the Valkey and KeyDB single node deployments, the `GET` command consistenly was the fasted of the three request types.
For these two exceptions, both `DEL` and `GET` exhibited the same latency. @fig_relative_cmd_latency shows the relative latency of the `GET` and `DEL` commands compared to the latency of the `SET` command. \ \

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

Looking at the frequency of recorded latencies, we observe a sudden increase in frequency at around $260 mu s$ for all applications and all cluster sizes. An example of the sudden spike in latency frequence in given in @fig_latency_freq_redis.

#figure(
  caption: "Frequencies of recorded latencies for a single node Redis deployment"
)[
  #image("./images/1-nodes/redis_latency_frequency.png")
] <fig_latency_freq_redis>

== Acdis

When running the benchmarks agains Acdis, we faced issues that 
 the benchmarks did not run to completion, as the application was stopped by the OS during the run.

After investigation we found that the memory usage of Acdis was considerably higher than that of the Redis derivatives.
Before end of the benchmark, the application attempted to reserve more memory than was available for the Virtual Machine.
As a result the operating system stopped the SUT early with an "out-of memory" exception.
@fig_gcp_memory_glibc shows the memory consumption for a three node Acdis deployment as recorded by the Google Compute Engine.

#figure(
  caption: "Memory usage for a three node Acdis deployment. Note that the tails after the 'OOM-Killed' marker are artificially extended for better readability of the graph." 
)[
  #image("./images/GCP_Memory_glibc.png")
] <fig_gcp_memory_glibc>

// Discussion
= Discussion <Sec_Discussion>

= Conclusion

= Outlook
