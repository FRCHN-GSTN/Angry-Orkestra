---
name: architecture-analysis
description: >
  Panduan analisa arsitektur & quality review proyek CodeIgniter 4 untuk worker
  code-reviewer. Menilai struktur direktori (app/, public/, writable/, tests/),
  kualitas kode (controller/model/view, routing, validasi), arsitektur
  (pemisahan tanggung jawab, pola MVC vs HMVC, layering), keamanan dasar
  (CSRF, XSS, SQL injection), dan merumuskan verdict berbasis bukti.
  Dipakai saat tugas melibatkan analisa struktur proyek, review arsitektur,
  atau quality review sebelum merge/rilis.
triggers:
  - arsitektur
  - analisa
  - quality review
  - struktur
  - CI4
  - code review
---

# Analisa Arsitektur & Quality Review Proyek CodeIgniter 4

## Tujuan

Menilai kesehatan arsitektur proyek CodeIgniter 4 secara objektif dan
berbasis bukti (bukan opini), lalu merumuskan verdict yang dapat
dipertanggungjawabkan: **ROMBAK total**, **IMPROVE sebagian**, atau
**BIARKAN**.

Gunakan skill ini saat menerima tugas review yang menyebut kata kunci:
arsitektur, analisa, quality review, struktur, CI4, code review.

## Prinsip Dasar

1. **Bukti > opini.** Setiap penilaian harus merujuk pada file/kode nyata.
   Jangan menilai "rapi" tanpa menyebut path dan alasan konkret.
2. **Standar minimum CI4.** Ikuti konvensi framework: `app/Config`,
   `app/Controllers`, `app/Models`, `app/Views`, `app/Services`,
   `app/Entities`, `app/Filters`, `writable/`, `public/`, `tests/`.
3. **Fokus pada dampak, bukan selera.** Pertimbangkan dampak terhadap
   maintainability, keamanan, dan biaya perubahan.

## Checklist Penilaian Struktur Direktori

Gunakan checklist berikut saat menilai struktur proyek:

- [ ] `app/` berisi `Controllers/`, `Models/`, `Views/`, `Config/`,
      `Services/`, `Entities/`, `Filters/`, `Helpers/`.
- [ ] `public/` hanya berisi file yang boleh diakses publik (index.php,
      asset statis). Tidak ada file internal di `public/`.
- [ ] `writable/` ada di luar `public/` dan tidak dapat diakses via URL.
- [ ] `tests/` ada dan berisi test yang dapat dijalankan.
- [ ] `vendor/` dan `writable/` tidak dikomit ke git (ada `.gitignore`).
- [ ] Tidak ada controller "god object" (satu controller menangani >5
      resource atau >300 baris logika).

## Checklist Kualitas Kode

- [ ] Controller tipis: logika bisnis dipindah ke Model/Service/Entity.
- [ ] Model menggunakan `$allowedFields` untuk mass assignment (mencegah
      mass assignment vulnerability).
- [ ] Query tidak di-hardcode mentah di View; query ada di Model.
- [ ] Validasi menggunakan `$validation` rules terpusat, bukan inline
      tanpa aturan.
- [ ] Tidak ada `SELECT *` yang tidak perlu atau query dalam loop
      (N+1 problem).
- [ ] Routing dipusatkan di `app/Config/Routes.php`; tidak ada routing
      tersebar di controller.

## Checklist Arsitektur (MVC vs HMVC vs Layering)

- [ ] Pemisahan tanggung jawab jelas: Controller (HTTP), Model (data),
      View (presentasi), Service (logika domain).
- [ ] Model tidak berisi logika presentasi (HTML, redirect).
- [ ] Controller tidak berisi query SQL mentah.
- [ ] HMVC dipakai hanya bila ada modul yang benar-benar reusable.
- [ ] Tidak ada View yang berisi logika bisnis kompleks (loops, kondisi
      yang seharusnya di controller).
- [ ] Layering: Services dapat dipanggil dari Controller dan Model;
      tidak ada dependency sirkular antar Service.

## Checklist Keamanan Dasar

- [ ] CSRF protection aktif di `app/Config/Filters.php` (filter `csrf`).
- [ ] Semua output di-escape menggunakan `esc()` di View, atau autoescape
      aktif.
- [ ] Query menggunakan Query Builder / prepared statement, bukan
      string concatenation.
- [ ] Tidak ada penggunaan `$this->request->getPost()` yang langsung
      di-echo tanpa `esc()`.
- [ ] Tidak ada hardcoded credential di kode (password, API key,
      secret) atau di `.env` yang dikomit.

## Rubrik Verdict

### 1. ROMBAK Total

Pilih verdict ini bila **salah satu** kondisi berikut terpenuhi:

- **Keamanan kritis**: ada SQL injection aktif (query mentah dari input
  user), XSS tanpa escape, atau CSRF nonaktif di form penting.
- **Arsitektur runtuh**: controller >1000 baris dengan query dan HTML
  bercampur, atau tidak ada pemisahan sama sekali (HTML di controller,
  query di View).
- **Data loss risk**: mass assignment tidak dibatasi (`$allowedFields`
  kosong) pada tabel sensitif.

**Contoh bukti**: `app/Controllers/UserController.php` baris 42 berisi
`$db->query("SELECT * FROM users WHERE id = ".$_GET['id'])` tanpa
parameter binding.

### 2. IMPROVE Sebagian

Pilih verdict ini bila **tidak ada keamanan kritis**, namun:

- Ada N+1 query, query dalam loop, atau penggunaan `SELECT *` berlebihan.
- Ada controller gemuk (>300 baris) yang layak dipecah ke Service.
- Validasi tidak terpusat (inline di controller tanpa rule file).
- Ada View yang memuat logika bisnis ringan.

**Contoh bukti**: `app/Controllers/ReportController.php` baris 120
memanggil `$this->userModel->findAll()` di dalam loop `foreach`.

### 3. BIARKAN

Pilih verdict ini bila:

- Struktur sesuai konvensi CI4.
- Keamanan dasar terpenuhi.
- Tidak ada masalah performa atau maintainability yang signifikan.
- Hanya ada temuan kosmetik (penamaan minor, komentar kurang).

**Contoh bukti**: struktur direktori sesuai konvensi, filter CSRF aktif
di `app/Config/Filters.php`, semua query menggunakan Query Builder.

## Format Output Verdict

Tulis verdict dengan format berikut agar dapat dipertanggungjawabkan:

```
VERDICT: [ROMBAK TOTAL | IMPROVE SEBAGIAN | BIARKAN]

BUKTI UTAMA:
- [path:line] [deskripsi singkat temuan]
- [path:line] [deskripsi singkat temuan]

REKOMENDASI:
- [langkah perbaikan spesifik, bukan general]

PRIORITAS: [P0 - Kritikal | P1 - Tinggi | P2 - Sedang | P3 - Rendah]
```

## Prosedur Kerja

1. **Pindai struktur**: baca isi `app/`, `public/`, `writable/`, `tests/`.
2. **Baca Config kunci**: `app/Config/Filters.php` (CSRF), `app/Config/Database.php`,
   `app/Config/Routes.php`.
3. **Sample controllers & models**: baca 3-5 file per direktori, fokus
   pada yang paling kompleks.
4. **Cek pola berbahaya**: cari `$db->query(` dengan concatenation,
   `echo $_`, `getPost` tanpa `esc`, `$allowedFields`.
5. **Rumuskan verdict** menggunakan rubrik di atas, sertakan bukti path:line.

## Catatan Penting

- Jangan menyebut angka/versi yang tidak yakin (misal "CI4 v4.5" tanpa
  bukti). Sebut versi hanya bila terverifikasi dari `composer.json`.
- Jangan mengubah kode; tugas ini hanya analisa.
- Jika menemukan temuan keamanan kritis, tandai P0 dan segera laporkan
  ke orkestrator.
