---
name: task-clarity
description: Skill untuk menilai apakah deskripsi tugas dari user cukup jelas untuk dieksekusi. Dipakai orkestrator sebagai ambiguity guard sebelum delegasi.
---

# Task Clarity — Ambiguity Guard

## Prinsip Dasar
- Jangan pernah mengerjakan tugas yang tidak jelas. Menebak = buang effort + hasil salah.
- Bos (orkestrator) wajib menilai kejelasan SEBELUM delegasi.
- Kalau tidak jelas → tolak & minta klarifikasi, bukan menebak.
- Klarifikasi lebih murah daripada mengerjakan hal yang salah.

## Checklist Ambiguity Guard
- [ ] Apakah tujuan akhir task jelas?
- [ ] Apakah output yang diharapkan jelas (file/dokumen/fitur)?
- [ ] Apakah scope cukup spesifik (bukan "perbaiki semua")?
- [ ] Apakah ada referensi/lokasi yang jelas (file/path/modul)?
- [ ] Apakah ada cukup konteks untuk worker bekerja?
- [ ] Apakah ada kriteria selesai?

## Keputusan
- **≥ 4/6 jelas** → lanjut eksekusi.
- **< 4/6 ambigu** → TOLAK: minta klarifikasi ke user dengan pertanyaan spesifik.

## Contoh Tolak
> "Maaf, tugasnya masih kurang jelas. Apa output yang kamu mau? Scope-nya apa? Tolong perjelas dulu, biar aku gak salah kerja."

## Kapan Memakai Masing-masing Poin
- **Tujuan** → tanyakan: "untuk apa hasil ini dipakai?"
- **Output** → tanyakan: "file/dokumen apa persisnya?"
- **Scope** → tanyakan: "cukup 1 file, atau seluruh modul?"
- **Lokasi** → tanyakan: "di proyek/folder mana?"
- **Konteks** → tanyakan: "ada referensi atau batasan khusus?"
- **Kriteria selesai** → tanyakan: "bagaimana saya tahu sudah selesai?"

## Contoh Klarifikasi yang Baik
> "Sebelum aku kerja, 3 hal perlu jelas: (1) Output-nya file Excel atau CSV? (2) Scope-nya semua modul atau hanya modul X? (3) Di folder mana hasilnya ditaruh? Kalau ketiganya jelas, aku langsung kerja."

## Anti-pattern
- Menebak maksud task yang samar.
- Mengerjakan "perbaiki semua" tanpa kriteria selesai.
- Menerima task tanpa lokasi/referensi yang jelas.
- Menanyakan 10 pertanyaan padahal 3 sudah cukup.
