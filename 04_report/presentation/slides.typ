#import "@preview/definitely-not-isec-slides:1.0.1": *

#let primary_color = rgb("#C50E1F")

#show: definitely-not-isec-theme.with(
  aspect-ratio: "16-9",
  slide-alignment: top,
  progress-bar: true,
  institute: [TU Berlin],
  logo: [],
  config-info(
    title: [How does per-command latency \ 
      compare between open source \
      key-value stores in clusters \
      of different sizes?],
    subtitle: [],
    authors: ([*Nils Deckert*],),
    extra: [Cloud Service Benchmarking WiSe 2025/26],
    footer: [Nils Deckert],
    download-qr: "",
  ),
  config-common(
    handout: false,
  ),
  config-colors(
      primary: primary_color,
  ),
)

#let cite_bottom(lbl: "atikogluWorkloadAnalysisLargeScale2012") = {
  place(
      bottom + right,
      dx: -5pt,
      cite(label(lbl))
    )
}

// -------------------------------[[ CUT HERE ]]--------------------------------
//
// === Available slides ===
//
// #title-slide()
// #standout-slide(title)
// #section-slide(title,subtitle)
// #blank-slide()
// #slide(title)
//
// === Available macros ===
//
// #quote-block(body)
// #color-block(title, body)
// #icon-block(title, icon, body)
//
// === Presenting with pdfpc ===
//
// Use #note("...") to add pdfpc presenter annotations on a specific slide
// Before presenting, export all notes to a pdfpc file:
// $ typst query slides.typ --field value --one "<pdfpc-file>" > slides.pdfpc
// $ pdfpc slides.pdf
//
// -------------------------------[[ CUT HERE ]]--------------------------------
 
#title-slide()

#section-slide(title: "Systems under test")

#slide(title: "Systems under test")[
  #v(1em)
  #grid(
    columns: (25%, 25%, 25%, 25%),
    [ == Redis
      - In-memory key-value store
      - Most popular key-value store @akhtarPopularityRankingDatabase2023a
      - Popular as a cache
      
    ],
    [ == Valkey
      - Redis Fork
      - Backed by the Linux Foundation
    ],
    [== KeyDB
      - Redis Fork
      - Backed by Snap Inc.
      - "A faster drop in alternative to Redis" @KeyDBFasterRedisa
    ],
    [== Acdis
      - Case study for the actor model
      - Redis compatible
      - Only supports `SET`, `GET`, `DELETE` commands
    ]
  )
]


#section-slide(title:"Benchmark Design")

#slide(title: "\"Workload Analysis of a Large-Scale Key-Value Store\"")[
  - Traces from Facebooks Memcached deployment
  - Five different pools
  - 284 billion requests
  - Provide statistical model to generate realistic benchmarking data

  #v(7em)

  #color-block(title: [Workload Analysis of a Large-Scale Key-Value Store \[Ati+12\]])[
    #cite(label("atikogluWorkloadAnalysisLargeScale2012"), form: "author")
  ]
]

#slide(title: "Sampled pools")[

  #table(
    columns: (20%, 80%),
    fill: (col, row) => if row == 3 { primary_color.lighten(90%) } else { none },
  )[*Pool*][*Description*][
    USR][user-account status information][
    APP][object metadata of one application][
    ETC][nonspecific, general-purpose][
    VAR][server-side browser information][
    SYS][system data on service location]

  #note("ETC is used as a general cache by multiple applications and is the largest of the pools")

  #cite_bottom()
]

#slide(title: "Distribution of request types")[
  #table(
    columns: (30%, 20%, 20%, 20%),
    fill: (col, row) => if row == 3 { primary_color.lighten(90%) } else { none },
  )[*Pool*][*GET*][
    *SET*#footnote("This includes all non-delete writing. E.g. SET, REPLACE, etc.")][
      *DELETE*][
   USR][>99.8%][\<0.1%][\<0.1%][
   APP][\~84%][\~4%][\~12%][
   ETC][\~70%][\~5%][\~25%][
   VAR][\~18%][\~82%][-][
   SYS][\~67%][\~33%][-]

   #note("The values here are only approximations, because the paper did not list exact values, only showed a graph.")

   #cite_bottom()
]

#slide(title: "Request sizes")[

  - `APP`: 
    - 90% of keys 31 bytes long
    - 30% of `SET` values are 270 bytes long
  - `USR`:
    - Only two key sizes: 16 bytes
    - One value size: 2 bytes
  - `ETC`:
    - Most heterogeneous
    - Requests with 2, 3 & 11 byte values equal ~40%

  #cite_bottom()
]

#slide(title: "ETC: Key length")[
    #figure(caption: "Distribution of key sizes (ETC)")[
      #image("graph_code/etc_key_size.png")
    ]
]

#slide(title: "ETC: Value size")[
    #figure(caption: "Distribution of value sizes (ETC)")[
      #image("graph_code/etc_value_size.png")
    ]
]

#slide(title: "Not considered factors")[
  - Temporal Patterns
  - Cache behavior
  - Repeating Keys
]

#slide(title: "SUTs")[
  - Single instance
  - Three node cluster
  - Four node cluster
  - Five node cluster

  #v(2em)

  == Clients & Requests

  1. Warm-up cluster with 6 million `SET` requests
  2. 3 \* 32 clients
  3. 60 million requests (70% `GET`, 5% `SET`, 25% `DELETE`)
]


// #slide(title: [Cache Hits])[
//   #quote-block[
//     How many GET requests can be served?
//   ]
//
//   #text(weight: "bold", "Hit Rate:") 81,4%
//
//   #table(columns:6, table.header(
//     [*Pool*],
//     "APP",
//     "VAR",
//     "SYS",
//     "USR",
//     [*ETC*],
//     [*Hit rate*],
//     "92.9%",
//     "93.7%",
//     "98.7%",
//     "98.2%",
//     [*81.4*]
//   ))
//
//   #quote-block[
//     Why are keys missing?
//   ]
//
//   #table(columns: 4, table.header([*Miss Category*], "New", "Deleted", "Evicted"), [*Ratio*], "70%", "8%", "22%")
//
//
//   #place(
//       bottom + right,
//       dx: -5pt,
//       cite(label("atikogluWorkloadAnalysisLargeScale2012"))
//     )
// ]


// ============== BENCHMARK SETUP ===============

#section-slide(title: "Benchmark Setup")

#slide(title: "Environment")[
  - Google Compute Engine
    - n4-highcpu-4
      - 4 vCPUs
      - 8GB RAM
    - europe-north2-a (Stockholm)
  - 3 Benchmark VMs
  - 1, 3, 4, 5 VMs for SUT cluster
  - Ubuntu 24.04 (22.04 for KeyDB #footnote("No release available for 24.04"))
]

#slide(title: "Tech Stack")[
  #grid(
    columns: (50%, 50%),
    [
      == Ansible
       - Provision VMs
       - Install SUTs, Benchmarking software
       - Orchestrate benchmark
      == Rust
       - Generate Keys & Values
       - Send commands to SUT
       - Record latency
    ],
    [
      == Python
       - Analyze results
       - Generate plots
      == (Typst)
       - This presentation
    ]
  )
]

#section-slide(title: "Benchmark Results")

// #slide(title: "Validate Results")[
//   #image("./images/acdis_latency_by_command.png")
// ]

#slide(title: "Latency by command")[
  #grid(
    columns: (50%, 50%),
    rows: (50%, 50%),
    [
      #image("./images/redis_latency_by_command.png")
      #image("./images/valkey_latency_by_command.png")
    ],
    [
      #image("./images/keydb_latency_by_command.png")
      #image("./images/acdis_latency_by_command.png")
    ]
  )
  #note("Graphs are very small on purpose. Latency between the commands SET, GET, DELETE are very similar")
]

#let suts = ("redis", "valkey", "keydb", "acdis");

#for sut in suts [
  #let display_name = upper(sut.at(0)) + sut.slice(1)
  #slide(title: "Latency by cluster size: " + display_name)[
    #align(center)[
      #image("./images/" + sut + "_latency_by_cluster_size.png")
    ]
  ]
]

#slide(title: "Latency by cluster size")[
  #align(center)[
    #image("./images/barchart_latency.png")
  ]
]

#slide(title: "Latency by Application")[
]

// #slide(title: [First Slide])[
//   #quote-block[
//     Good luck with your presentation!
//   ]
//
//   #color-block(title: "Mein title")[
//     hallo das Hier is mein color block zum hervorheben
//   ]
//
//   #note("This will show on pdfpc speaker notes ;)")
// ]

#slide(title: [Bibliography])[
  #bibliography("refs.bib")
]
