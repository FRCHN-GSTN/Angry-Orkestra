# angry-orkestra — Sumber Kebenaran Tunggal untuk Skill & Agent

> Konsep B (best practice): semua skill & agent disimpan di sini (versioned, portabel),
> lalu di-sync ke platform aktif (OpenCode / Claude / Cursor).
>
> **Aturan emas:** edit HANYA di master. Jangan pernah edit langsung di lokasi platform
> (`~/.config/opencode/`, `~/.claude/`, dll) — perubahan di sana akan tertimpa saat sync.

> © 2026 [FRCHN](https://github.com/FRCHN) — Licensed under MIT License.

---

## Struktur

```
angry-orkestra/
├── README.md            ← file ini (panduan)
├── sync.sh              ← script sinkronisasi multi-platform (bash)
├── .gitignore           ← abaikan artefak sync (backup) dari git
├── agents/              ← definisi agent (portabel)
│   ├── orchestrator.md
│   ├── skill-author.md
│   ├── flutter-mobile-dev.md
│   └── db-admin.md
├── skills/              ← semua skill (portabel)
│   ├── domain-guard/SKILL.md
│   └── task-clarity/SKILL.md
└── config/
    └── categories.yaml  ← peta kategori tugas → worker + skill
```

---

## Cara Pakai

### 1. Edit di master (sumber kebenaran)
- Tambah/ubah skill → `skills/<nama>/SKILL.md`
- Tambah/ubah agent → `agents/<nama>.md`
- Ubah pemetaan kategori → `config/categories.yaml`

### 2. Sync ke platform aktif
```bash
./sync.sh --opencode   # OpenCode  → ~/.config/opencode/agents + skills
./sync.sh --claude     # Claude    → ~/.claude/agents + skills
./sync.sh --cursor     # Cursor    → .cursor/rules
```

### 3. Verifikasi & rollback
```bash
./sync.sh --status     # bandingkan jumlah file master vs platform
./sync.sh --dry-run    # preview yang akan disalin, tanpa menyalin
```
- File yang ditimpa di-backup otomatis ke `.sync-backup-<timestamp>/` di platform.
- Rollback: salin kembali file dari folder backup tersebut.

---

## Prinsip Best Practice

1. **Satu sumber kebenaran** — semua definisi ada di master; platform hanya menerima salinan.
2. **Non-destructive** — sync menimpa file master saja, TIDAK menghapus agent/skill lain di platform.
3. **Backup otomatis** — setiap file yang ditimpa disalin dulu ke `.sync-backup-<timestamp>/` (safe).
4. **Portabel** — struktur sama untuk semua platform; hanya lokasi folder yang beda (diatur di `sync.sh`).
5. **Versioned** — master di-commit ke git; `.gitignore` mencegah artefak sync masuk repo.
6. **Edit di master, bukan di platform** — mencegah drift & konflik saat sync berikutnya.

---

## Batasan (jujur)

- **Cursor**: agent tidak didukung penuh (hanya rules); skill sebagian — verifikasi sebelum dipakai.
- **Provider LLM** (Claude/GPT/Gemini) tidak memengaruhi topologi — yang penting harness/CLI.
- **Format frontmatter** sebagian kecil beda antar platform → cek saat sync pertama ke platform baru.
- **Windows**: `sync.sh` butuh bash (Git Bash/WSL). Lokasi OpenCode: `%USERPROFILE%\.config\opencode\`.

---

## Catatan Arsitektur (koneksi ke pipeline)

- **Fase 1 (Bootstrap)**: bos cek skill/agent → belum ada → `skill-author` bikin → **simpan ke master** → sync.
- **Fase 2 (Eksekusi)**: skill/agent sudah ada → bos langsung delegasi ke worker (reuse, tanpa bikin ulang).
- **Auto-cleanup**: skill sekali-pakai dihapus dari master; arsip analisa disimpan di `archive/`.

Topologi lengkap ada di `../ARCHITECTURE.md` (level project root).
