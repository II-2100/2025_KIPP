Cara pakai singkat (II-2100 Assessment Pack)
===========================================
1) Buka setiap file 'form_*_penilaian.csv' untuk menilai tugas – isi skor 1–5 pada setiap kriteria.
   Kolom Rata2_Level dan Skor_0_100 akan terhitung otomatis di Excel/Sheets.
2) Rekap 'Skor_0_100' per mahasiswa ke 'kelas_aggregasi.csv' pada kolom tugas yang relevan:
   QZ1, QZ2, UTS1_AllAboutMe, UTS2_SongForYou, UTS3_MyStories, UTS4_MySHAPE, UTS5_MyPersonalReview, UAS1_MyConcepts, UAS2_MyOpinions, UAS3_MyInnovations, UAS4_MyKnowledge, UAS5_MyProfessionalReviews.
   QZ1 = rerata kuis Minggu 1–7, QZ2 = rerata kuis Minggu 8–14 (skala 0–100).
3) Buka 'weights_and_targets.csv' untuk melihat/menyetel Target CPMK dan bobot (weights).
   Default target tiap CPMK = 70%.
4) Di 'kelas_aggregasi.csv', hitung CPMK% dan Nilai Akhir sbb (rumus Excel – contoh untuk baris data pertama, baris 2):
   CPMK1% = 0.2*QZ1 + 0.25*UAS1_MyConcepts + 0.15*UTS4_MySHAPE + 0.15*UTS5_MyPersonalReview + 0.25*UAS4_MyKnowledge
   CPMK2% = 0.2*UTS1_AllAboutMe + 0.25*UTS2_SongForYou + 0.25*UTS3_MyStories + 0.15*UTS4_MySHAPE + 0.15*UTS5_MyPersonalReview
   CPMK3% = 0.25*QZ2 + 0.15*UAS1_MyConcepts + 0.35*UAS2_MyOpinions + 0.25*UAS4_MyKnowledge
   CPMK4% = 0.55*UAS3_MyInnovations + 0.45*UAS5_MyProfessionalReviews
   Overall% = AVERAGE(CPMK1%,CPMK2%,CPMK3%,CPMK4%)
   FinalLetter (A/B/C/D/E) logika default:
      - A: Overall% >= Target+15 dan semua CPMK% >= Target
      - B: Overall% >= Target dan semua CPMK% >= Target
      - C: Overall% >= Target-10
      - D: Overall% >= Target-20
      - E: selain itu
   Anda bisa menerapkan rumus IF bertingkat di Excel/Sheets menggunakan nilai Target yang sama (mis. 70).
5) Sesuaikan rubrik/criteria sesuai kebutuhan mata kuliah; CSV rubrics dapat diimpor sebagai pedoman/foto kopi ke LMS.

Catatan:
- Rubrik UAS1 (Concepts), UAS2 (Opinions), dan UTS3 (Stories) telah disejajarkan dengan rubrik terlampir di PDF pengguna.
- Mapping bobot ke CPMK disusun agar total per CPMK ~ setara; silakan sesuaikan di 'weights_and_targets.csv'.
