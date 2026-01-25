#import "@preview/definitely-not-isec-slides:1.0.1": *

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
      primary: rgb("#C50E1F"),
  ),
)

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

#section-slide(title:"Benchmark Design")

#slide(title: [Cache Hits])[
  #quote-block[
    How many GET requests can be served?
  ]

  #text(weight: "bold", "Hit Rate:") 81,4%

  #table(columns:6, table.header(
    [*Pool*],
    "APP",
    "VAR",
    "SYS",
    "USR",
    [*ETC*],
    [*Hit rate*],
    "92.9%",
    "93.7%",
    "98.7%",
    "98.2%",
    [*81.4*]
  ))

  #quote-block[
    Why are keys missing?
  ]

  #table(columns: 4, table.header([*Miss Category*], "New", "Deleted", "Evicted"), [*Ratio*], "70%", "8%", "22%")

  
  #place(
      bottom + right,
      dx: -5pt,
      cite(label("atikogluWorkloadAnalysisLargeScale2012"))
    )
]

#section-slide(title: "Benchmark results")

#slide(title: "Validate Results")[
  #image("./images/acdis_latency_by_command.png")
]

#slide(title: "Redis - Latency by command")[
  #image("./images/redis_latency_by_command.png")
]

#slide(title: "Valkey - Latency by command")[
  #image("./images/valkey_latency_by_command.png")
]

#slide(title: "KeyDB - Latency by command")[
  #image("./images/keydb_latency_by_command.png")
]

#slide(title: "Acdis - Latency by command")[
  #image("./images/acdis_latency_by_command.png")
]

#slide(title: "Latency by Application")[
]


#slide(title: [First Slide])[
  #quote-block[
    Good luck with your presentation!
  ]

  #color-block(title: "Mein title")[
    hallo das Hier is mein color block zum hervorheben
  ]

  #note("This will show on pdfpc speaker notes ;)")
]

#slide(title: [Bibliography])[
  #bibliography("refs.bib")
]
