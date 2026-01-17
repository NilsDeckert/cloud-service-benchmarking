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

#slide(title: [Cache Hits])[
  #quote-block[
    How many GET requests can be served?
  ]

  #text(weight: "bold", "Hit Rate:") 81%

  #quote-block[
    Why are keys missing?
  ]

  #table(columns: 4, table.header([*Miss Category*], "New", "Deleted", "Evicted"), [*Ratio*], "70%", "8%", "22%")

  
  #place(
      bottom + right,
      dx: -5pt,
      cite(label("emg25template"))
    )
  @emg25template
]

#slide(title: [First Slide])[
  #quote-block[
    Good luck with your presentation! @emg25template
  ]

  #color-block(title: "Mein title")[
    hallo das Hier is mein color block zum hervorheben
  ]

  #note("This will show on pdfpc speaker notes ;)")
]

#slide(title: [Bibliography])[
  #bibliography("bibliography.bib")
]
