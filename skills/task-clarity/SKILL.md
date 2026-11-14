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

## Anti-pattern
- Menebak maksud task yang samar.
- Mengerjakan "perbaiki semua" tanpa kriteria selesai.
- Menerima task tanpa lokasi/referensi yang jelas.
