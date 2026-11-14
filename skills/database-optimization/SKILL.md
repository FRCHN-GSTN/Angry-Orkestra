---
name: database-optimization
description: Skill untuk mengoptimasi performa database (khusus PostgreSQL). Dipakai worker db-admin saat menangani query lambat, perancangan index, schema tuning, dan diagnosis bottleneck database.
---

# Database Optimization — Tuning & Diagnosis PostgreSQL

## Prinsip Dasar
- Ukur dulu, baru ubah. Jangan pernah mengubah query/index/schema tanpa data baseline.
- Optimasi yang tidak terukur = perubahan buta. Selalu verifikasi dampak nyata.
- Amankan dulu: sebelum produksi, pastikan ada cadangan data (backup).
- Perubahan kecil + terukur lebih baik daripada refaktor besar tanpa bukti.

## Checklist Optimasi (JALANKAN BERURUTAN)
- [ ] **Baseline**: jalankan query bermasalah, catat waktu eksekusi (ms) & `EXPLAIN ANALYZE`.
- [ ] **Identifikasi**: baca `EXPLAIN ANALYZE` output. Cari: Seq Scan pada tabel besar, nested loop mahal, sort/spill ke disk, filter yang membuang banyak baris.
- [ ] **Hipotesis**: tulis 1 hipotesis spesifik. Contoh: "Seq Scan karena kolom `email` belum ter-index".
- [ ] **Usul solusi**: pilih salah satu (1) tambah/ubah index, (2) refactor query, (3) ubah schema/konfigurasi. Prioritaskan yang paling murah.
- [ ] **Terapkan (non-prod dulu)**: jalankan perubahan di environment non-produksi. Simpan backup skrip rollback.
- [ ] **Verifikasi**: jalankan ulang `EXPLAIN ANALYZE`. Bandingkan: apakah lebih cepat + plan lebih baik?
- [ ] **Dokumentasi**: catat sebelum/sesudah (ms, plan change). Lapor ke bos dengan bukti.

## Rubrik Kualitas (untuk validasi sendiri)
| Kriteria | Buruk | Cukup | Baik |
|---|---|---|---|
| Baseline terukur | Tidak ada | Ada angka kasar | Ada `EXPLAIN ANALYZE` lengkap |
| Diagnosis | Menebak | Sebut gejala | Sebut akar masalah di plan |
| Solusi | Refaktor besar buta | 1 perubahan terukur | Perubahan minimal + rollback siap |
| Verifikasi | Tidak ada | Angka sebelum/sesudah | Angka + penjelasan plan change |
| Risiko | Abaikan | Sebut singkat | Skrip rollback + dampak index ditulis |

## Contoh Perbaikan Slow Query
> "Bos, aku cek dulu... Query `SELECT * FROM orders WHERE user_id = X ORDER BY created_at DESC` ambil 1.2s. Di `EXPLAIN ANALYZE` muncul **Seq Scan** di tabel `orders` (2 juta baris) + **Sort** di memory. Diagnosis: tidak ada index di `(user_id, created_at)`. Aku tambahkan `CREATE INDEX CONCURRENTLY idx_orders_user_created ON orders(user_id, created_at DESC);`. Sesudahnya: 12ms (index scan), plan sehat. Rollback: `DROP INDEX idx_orders_user_created;`. Lapor selesai!"

## Anti-pattern
- Menambah index tanpa lihat plan (index salah tidak terpakai).
- Mengubah query tanpa ukur baseline ("harusnya lebih cepat").
- Optimasi prematur: mengubah hal yang belum terbukti lambat.
- Menambah index di setiap kolom tanpa pikir dampak tulis (write overhead).
- Claim angka peningkatan tanpa jalankan query asli.

## Kapan Berhenti
- Jika query sudah memenuhi SLA (misal < 50ms untuk use case ini) → berhenti, jangan micro-optimize.
- Jika butuh ubah arsitektur (misal partitioning besar) → lapor bos, minta keputusan arsitektur.
- Jika masalah bukan di query tapi di sisi aplikasi (N+1, volume) → sarankan ke worker lain.

## Output Contract
Setiap tugas database diakhiri dengan: (1) baseline ms, (2) diagnosis dari plan, (3) perubahan yang diterapkan, (4) sesudah ms + plan change, (5) skrip rollback bila ada.
