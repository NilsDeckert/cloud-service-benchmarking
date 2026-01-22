#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Latency comparison of key-value stores for different cluster size],
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

= Introduction

Key-Value stores are a common part of modern online systems.
The most prominent example is Redis #footnote[https://redis.io]. Caused by the change of license used by Redis in 20XX, multiple open source alternatives emerged. Valkey #footnote[https://valkey.io] and KeyDB #footnote[https://docs.keydb.dev] are forks of the original Redis project. Acdis #footnote[https://github.com/NilsDeckert/acdis] is a case study of the actor model, implementing a redis-compatible application.

#linebreak()

This paper aims to provide a comparison between the four open-source key-value stores Redis, Valkey, KeyDB and Acids. As the main metric for this comparison, we will focus on latency. To assess their capabilities in multiple settings, we will benchmark the systems in both single-node and cluster deployments of different sizes.

= Benchmark Design

== System Setup<Sec_SystemSetup>

In order to provide an accurate assessment for the latency of the tested systems, we examine the systems under various constellations:

- Single Node
- Cluster of three nodes
- Cluster of five nodes (?)

== Load Generation<Sec_LoadGeneration>

In order to generate meaningful results, we need to subject the application to a realistic usage scenario. #cite(<atikogluWorkloadAnalysisLargeScale2012>, form: "author") collected traces on the memcached cluster used at Facebook in #cite(<atikogluWorkloadAnalysisLargeScale2012>, form: "year"). Based on these traces, they provided a model to recreate realistic usage behavior for key-value stores.

The model suggests a 70% / 25% / 5% ratio #footnote[Approximate values, the paper only shows a barchart without providing concrete numbers.] of the received GET / DEL / SET requests. Additionally, it provides distributions for key and value lengths.

We will execute the workload described in @atikogluWorkloadAnalysisLargeScale2012 on all setups described in @Sec_SystemSetup.

== Hardware<Sec_Hardware>

The key-value stores and the benchmarking software are deployed to Google Cloud Compute Engine virtual machines.
The key-value stores are running on `n4-standard-highcpu` machines. The benchmarking software is deployed to `n4-standard-n` instances.

