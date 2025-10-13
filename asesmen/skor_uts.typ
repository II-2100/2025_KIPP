// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: doc => article(
  title: [Asesement UTS Berbasis Rubrik],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

Berikut adalah panduan untuk menilai TUGAS UTS Matakuliah II-2100 bagi seorang mahasiswa individu. Tugas dibuat dalam bentuk laman web dengan URL TUGAS UTS yang diberikan. Menggunakan panduan ini, penilai dapat melakukan asesmen terhadap tugas orang lain, maupun self asesmen pada laporannya sendiri

= Instruksi:
<instruksi>
+ Pelajari Panduan di 'https:\/\/ii-2100.github.io/2025\_KIPP/asesmen.html' Dimana terdapat lima TUGAS: UTS-1, UTS-2, UTS-3, UTS-4, UTS-5
+ Pelajari Rubrik setiap TUGAS yang ada dalam dokumen ini
+ Temukan Tugas Mahasiswa di URL TUGAS UTS yang diberikan. Halaman pertama (index.html) adalah UTS-1. Dari portal ini penilia dapat pergi ke UTS-2 dan seteursnya.
+ Untuk Setiap TUGAS gunakan Rubrik yang sesuai untuk menilai Tugas
+ Laporkan Hasil Pengukuran menggunakan Template di bawah, beserta saran perbaikan.

= #strong[Bentuk-bentuk Asesmen:]
<bentuk-bentuk-asesmen>
Untuk mengukur CPMK tersebut, asesmen akan menggunakan beberapa bentuk penilaian, yaitu:

+ #strong[Kuis Materi Topik Setiap Minggu (Q-1 s/d Q-14):] Mengukur pemahaman konseptual dari 14 topik perkuliahan yang disampaikan setiap minggu.
+ #strong[Ujian Tengah Semester (UTS-1 s/d UTS-5):] Fokus pada proyek demonstrasi komunikasi personal
  + UTS-1 All About Me, berisikan pesan yang memperkenalkan sosok diri kita
  + UTS-2 Song for you, berisikan pesan berbentuk puisi, lago, dan/atau viodeo clip\[
  + UTS-3 My Stories for You, berisikan kisah inspiratif dan menarik yang Anda ingin bagikan dengan pribadi lain
  + UTS-4 My Shape, berisikan laporan siapa Anda berdasar hasil sebuah lembar kerja
  + UTS-5 My Personal Review, berisikan telahan pesan personal berdasarkan rubrik
+ #strong[Ujian Akhir Semester (UAS-1 s/d UAS-5):] Fokus pada proyek demonstrasi komunikasi inspiratif publik yang mengaplikasikan konsep interpersonal.
  + UAS-1 My Concepts,
  + UAS-2 My Opinions,
  + UAS-3 My Innovations, berisikan desain suatu produk atau layanan yang membangun kapasitas dan efektivitas
  + UAS-4 My Knowledge, berisikan pengetahuan dan pembelajaran bagi masyarakat atas suatu topik dalam kuliah ini
  + UAS-5 My Professional Reviews, berisikan telaahan pesan publikl berdasarkan rubrik.

#figure([
#table(
  columns: (14.29%, 14.29%, 14.29%, 14.29%, 14.29%, 14.29%, 14.29%),
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([Jenis], [Asesmen], [Soft Deadline Minggu ke], [CPMK-1], [CPMK-2], [CPMK-3], [CPMK-4],),
  table.hline(),
  [Kuiz], [Q1-Q7], [], [14], [], [], [],
  [Kuiz], [Q8-Q14], [], [], [], [14], [],
  [UTS-1], [All About Me], [4], [], [6], [], [],
  [UTS-2], [My Song for You], [5], [], [7], [], [],
  [UTS-3], [My Stories for You], [6], [], [7], [], [],
  [UTS-4], [My Shape], [7], [], [6], [], [],
  [UTS-5], [My Personal Review], [8], [10], [], [], [],
  [UAS-1], [My Concepts], [12], [], [], [], [6],
  [UAS-2], [My Opinions], [13], [], [], [], [6],
  [UAS-3], [My Innovations], [14], [], [], [], [7],
  [UAS-4], [My Knowledge], [15], [], [], [], [7],
  [UAS-5], [My Professional Review], [16], [], [], [10], [],
  [], [], [], [24], [26], [24], [26],
)
], caption: figure.caption(
position: top, 
[
Tabel daftar bentuk asesmen, jadwal soft deadline, CPMK yang diukur serta bobot peniliaian dalam skala 100.
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-asesmen>


#set page(flipped: true)
= Rubrik UTS-1 All About Me
<rubrik-uts-1-all-about-me>
#figure([
#table(
  columns: 7,
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([], [Kriteria], [5 - Sangat Baik], [4 - Baik], [3 - Cukup], [2 - Kurang], [1 - Buruk],),
  table.hline(),
  [0], [Orisinalitas], [Narasi menghadirkan sudut pandang sangat unik ...], [Gagasan cukup orisinal dengan sedikit klise.], [Beberapa unsur orisinal namun banyak tema umum.], [Prediktabel dan orisinalitas rendah.], [Klise tanpa unsur baru.],
  [1], [Keterlibatan], [Sangat menarik dari awal hingga akhir, menjaga...], [Umumnya menarik dengan beberapa momen kuat.], [Cukup menarik; sesekali kehilangan atensi.], [Sulit mempertahankan atensi; konten kurang men...], [Tidak menarik dan tidak memikat audiens.],
  [2], [Humor], [Humor tepat waktu, relevan, dan efektif; serin...], [Humor baik; beberapa momen lucu.], [Humor cukup; sebagian berhasil, sebagian tidak.], [Humor terasa dipaksakan/tidak tepat; jarang be...], [Humor tidak efektif atau tidak ada.],
  [3], [Wawasan (Insight)], [Memberi pemahaman mendalam tentang daya tarik;...], [Pesan/insight jelas meski tidak sangat mendalam.], [Ada pesan umum namun dampak terbatas.], [Berusaha memberi pesan, tetapi dangkal atau ti...], [Tanpa insight bermakna tentang daya tarik inte...],
)
], caption: figure.caption(
position: top, 
[
Rubrik All About Me
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-rubric_uts-1>


= Rubrik UTS-2 Songs for You
<rubrik-uts-2-songs-for-you>
#figure([
#table(
  columns: 7,
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([], [Kriteria], [5 - Sangat Baik], [4 - Baik], [3 - Cukup], [2 - Kurang], [1 - Buruk],),
  table.hline(),
  [0], [Orisinalitas], [Ikatan digambarkan dengan cara sangat unik dan...], [Cukup orisinal, minim klise.], [Ada unsur orisinal namun banyak pola umum.], [Prediktabel; sedikit unsur baru.], [Klise tanpa kebaruan.],
  [1], [Keterlibatan], [Sangat memikat dari awal hingga akhir.], [Menarik di sebagian besar bagian.], [Cukup menarik; sesekali datar.], [Kurang memikat; banyak bagian lemah.], [Tidak memikat sama sekali.],
  [2], [Humor], [Konsisten efektif, relevan, dan tepat waktu.], [Umumnya baik; beberapa momen berhasil.], [Cukup; sebagian berhasil.], [Dipaksakan/tidak relevan; jarang berhasil.], [Tidak efektif atau tidak ada.],
  [3], [Inspirasi], [Sangat menginspirasi; kesan mendalam tentang k...], [Cukup menginspirasi; ada momen kuat.], [Ada unsur inspiratif; dampak terbatas.], [Berusaha menginspirasi namun dangkal.], [Tidak menginspirasi.],
)
], caption: figure.caption(
position: top, 
[
Rubrik Songs For You
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-rubric_uts-2>


= Rubrik UTS-3 My Story For You
<rubrik-uts-3-my-story-for-you>
#figure([
#table(
  columns: 7,
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([], [Kriteria], [5 - Sangat Baik], [4 - Baik], [3 - Cukup], [2 - Kurang], [1 - Buruk],),
  table.hline(),
  [0], [Orisinalitas], [Pengembangan cerita sangat unik dan segar.], [Lanjutan cukup orisinal, minim klise.], [Ada unsur baru namun banyak pola umum.], [Prediktabel; sedikit kebaruan.], [Tidak ada pengembangan baru.],
  [1], [Keterlibatan], [Sangat memikat dan konsisten menjaga atensi.], [Menarik dengan beberapa jeda kecil.], [Cukup menarik; ritme naik-turun.], [Kurang menarik; mudah kehilangan atensi.], [Tidak menarik.],
  [2], [Pengembangan Narasi], [Sambung rapi dengan bagian awal; menunjukkan p...], [Terkait baik dengan bagian awal; beberapa aspe...], [Melanjutkan cerita, namun ada ketidakselarasan...], [Hubungan longgar dengan bagian awal; pengemban...], [Terputus dari cerita awal; tanpa perkembangan ...],
  [3], [Inspirasi], [Sangat menginspirasi tentang kekuatan ikatan.], [Cukup menginspirasi; ada momen kuat.], [Ada unsur inspiratif; resonansi terbatas.], [Berusaha menginspirasi tetapi dangkal.], [Tidak menginspirasi.],
)
], caption: figure.caption(
position: top, 
[
Rubrik My Story for You
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-rubric_uts-3>


= Rubrik UTS-4 My SHAPEe
<rubrik-uts-4-my-shapee>
#figure([
#table(
  columns: 7,
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([], [Kriteria], [5 - Sangat Baik], [4 - Baik], [3 - Cukup], [2 - Kurang], [1 - Buruk],),
  table.hline(),
  [0], [Orisinalitas], [Pengembangan cerita sangat unik dan segar.], [Lanjutan cukup orisinal, minim klise.], [Ada unsur baru namun banyak pola umum.], [Prediktabel; sedikit kebaruan.], [Tidak ada pengembangan baru.],
  [1], [Keterlibatan], [Sangat memikat dan konsisten menjaga atensi.], [Menarik dengan beberapa jeda kecil.], [Cukup menarik; ritme naik-turun.], [Kurang menarik; mudah kehilangan atensi.], [Tidak menarik.],
  [2], [Pengembangan Narasi], [Sambung rapi dengan bagian awal; menunjukkan p...], [Terkait baik dengan bagian awal; beberapa aspe...], [Melanjutkan cerita, namun ada ketidakselarasan...], [Hubungan longgar dengan bagian awal; pengemban...], [Terputus dari cerita awal; tanpa perkembangan ...],
  [3], [Inspirasi], [Sangat menginspirasi tentang kekuatan ikatan.], [Cukup menginspirasi; ada momen kuat.], [Ada unsur inspiratif; resonansi terbatas.], [Berusaha menginspirasi tetapi dangkal.], [Tidak menginspirasi.],
)
], caption: figure.caption(
position: top, 
[
Rubrik MySHAPE
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-rubric_uts-4>


= Rubrik UTS-5 My Personal Reviews
<rubrik-uts-5-my-personal-reviews>
#figure([
#table(
  columns: 7,
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([], [Criterion], [Level1], [Level2], [Level3], [Level4], [Level5],),
  table.hline(),
  [0], [Pemahaman Konsep Interpersonal], [Tidak paham], [Kurang], [Cukup], [Paham], [Sangat paham & komprehensif],
  [1], [Analisis Kritis Pesan], [Tidak kritis], [Kurang kritis], [Cukup], [Kritis], [Sangat kritis & tajam],
  [2], [Argumentasi (Logos)], [Tidak logis], [Kurang koheren], [Cukup], [Logis], [Sangat logis & meyakinkan],
  [3], [Etos & Empati], [Tidak tampak], [Kurang], [Cukup], [Baik], [Sangat baik & berimbang],
  [4], [Rekomendasi Perbaikan], [Tidak ada], [Umum], [Cukup], [Konkret], [Sangat konkret & aplikatif],
)
], caption: figure.caption(
position: top, 
[
Rubrik My Personal Reviews
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-rubric_uts-5>


#set page(flipped: false)
= FORMAT LAPORAN
<format-laporan>
\*\* LAPORAN PENGUKURAN BERDASARKAN RUBRIK DARI TUGAS UTS\*\*

== Identifikasi
<identifikasi>
+ Nama Mahasiswa dan NIM Penyusun TUGAS
+ Nama Penilai:

== Tinjauan Umum
<tinjauan-umum>
Isi dengan tinjauan secara umum Karya yang di nilai

== Tinjauan Spesifik
<tinjauan-spesifik>
Isi dengan narasi penilaian secara khusus per UTS lalu beri hasil detail. beri juga saran perbaikan.

=== SKOR
<skor>
Hitung skor setiap TUGAS lalu hitung kontribusi nilai tersebut pada skor CPMK, menurut #ref(<tbl-asesmen>, supplement: [Table]).

#figure([
#table(
  columns: 6,
  align: (left,left,left,left,left,left,),
  table.header([UTS], [Skor], [CPMK-1], [CPMK-2], [CPMK-3], [CPMK-4],),
  table.hline(),
  [UTS-1], [], [], [], [], [],
  [UTS-2], [], [], [], [], [],
  [UTS-3], [], [], [], [], [],
  [UTS-4], [], [], [], [], [],
  [UTS-5], [], [], [], [], [],
  [Total], [], [], [], [], [],
)
], caption: figure.caption(
position: top, 
[
Daftar Nilai
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-skor-akhir>






