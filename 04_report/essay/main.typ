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
The most prominent example is Redis #footnote[https://redis.io]. Caused by the change of license used by Redis in 20XX, multiple open source alternatives emerged. Valkey #footnote[https://valkey.io] and KeyDB #footnote[https://docs.keydb.dev] are forks of the original Redis project. Acdis #footnote[https://github.com/NilsDeckert/acdis] is a case study of the actor model, implementing a redis-compatible application.

#linebreak()

This paper aims to provide a comparison between the four open-source key-value stores Redis, Valkey, KeyDB and Acids. As the main metric for this comparison, we will focus on latency. To assess their capabilities in multiple settings, we will benchmark the systems in both single-node and cluster deployments of different sizes.

= Systems Under Test

== Background

In 2014, Redis was the most-popular key-value store.
In XXXX, the license Redis was changed to closed source. This prompted multiple initiatives to fork the key-value store and continue on their own under open-source licenses.
The most-popular of these forks is Valkey, which is now backed by the Linux foundation, which in turn is backed by X, Y and Z amongst others.
KeyDB is another fork that claims to be a faster drop-in replacement to Redis. KeyDB is own by Snap Inc., the company behind Snapchat.

== Benchmark Objectives

// Methods

= Benchmark Design

In order to produce meaningful results, our benchmark aims to recreate realistic usage behavior.
For this, @Sec_Hardware will explain the execution environment chosen for our benchmarks.
Afterwards, @Sec_SystemSetup will describe the setups of the systems under test that were benchmarked.
Finally, @Sec_LoadGeneration will deep-dive into the data generation chosen to provide realistic usage data.

== Hardware<Sec_Hardware>

In order to provide a realistic execution environment for our benchmark, it is important to deploy the systems under tests to production ready machines on the internet.
Testing these systems locally and running all cluster nodes on the same machine would neglect how these cache systems are used in the real world.
The latency and error-proneness of network connections are an important factor in the real life operation of IT systems.

*Find some sources here on the popularity of cloud providers like aws or gce*

To recreate conditions that come close to that of real-world operations, we decided the deploy both the systems under tests and the load generators to virtual machines on the google compute engine.
The key-value stores and the benchmarking software are deployed to Google Cloud Compute Engine virtual machines.
The key-value stores are running on `n4-standard-highcpu` machines. The benchmarking software is deployed to `n4-standard-n` instances.
The virtual machines were deployed to the *XXXX* region (Stockholm) due to higher cpu usage quotas. Both the SUTs and the load generators were deployed to the same region.

== System Setup<Sec_SystemSetup>

In order to provide an accurate assessment for the latency of the tested systems, we examine the systems under various constellations:

- Single Node
- Cluster of three nodes
- Cluster of four nodes
- Cluster of five nodes

The minimum cluster size for Redis and its derivatives is three.
For the benchmarks, the upper bound of the tested cluster sizes was dictated by the enforced cpu quotas of the Google Compute Engine.
To assess how additional nodes help the cluster to cope with demand, we kept the same number of load generators while varying the size of the SUT cluster.

== Load Generation<Sec_LoadGeneration>

In order to generate meaningful results, we need to subject the application to a realistic usage scenario. #cite(<atikogluWorkloadAnalysisLargeScale2012>, form: "author") collected traces on the memcached cluster used at Facebook in #cite(<atikogluWorkloadAnalysisLargeScale2012>, form: "year"). Based on these traces, they provided a model to recreate realistic usage behavior for key-value stores.

The model suggests a 70% / 25% / 5% ratio #footnote[Approximate values, the paper only shows a barchart without providing concrete numbers.] of the received GET / DEL / SET requests. Additionally, it provides distributions for key and value lengths.

We will execute the workload described in @atikogluWorkloadAnalysisLargeScale2012 on all setups described in @Sec_SystemSetup.

// Results
= Results

#figure(
  caption: "Summary of the median latencies of the SUTs"
)[
  #image("./images/barchart_latency.png")
]

== Redis

#figure(
  caption: "Latency by command. Redis, one node"
)[
  #image("./images/1-nodes/redis_latency_by_command.png")
]

#figure(
  caption: "Latency by command. Redis, five nodes"
)[
  #image("./images/5-nodes/redis_latency_by_command.png")
]

// Discussion
= Discussion

= Conclusion

= Outlook
