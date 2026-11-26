#!/bin/bash
# sync.sh — Sinkronkan skill & agent dari angry-orkestra/ ke platform aktif.
#
# Cara pakai:
#   ./sync.sh --opencode   → salin ke ~/.config/opencode/agents/ + skills/
#   ./sync.sh --claude     → salin ke ~/.claude/agents/ + skills/
#   ./sync.sh --dry-run    → tampilkan apa yang akan disalin, tanpa menyalin
#   ./sync.sh --status     → bandingkan versi master vs platform
#
# Konsep: B (single source of truth). angry-orkestra/ = sumber kebenaran.
# Platform aktif hanya menerima salinan — jangan edit di sana, edit di master.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_DIR="$SCRIPT_DIR"

DRY_RUN=false
STATUS_ONLY=false
TARGET=""          # "opencode" | "claude" | "cursor"
TARGET_AGENTS=""   # path agents di platform
TARGET_SKILLS=""   # path skills di platform

# --- Konfigurasi lokasi per platform -------------------------------
# Deteksi HOME: di Git Bash/MSYS/WSL $HOME sudah POSIX (paling aman utk bash).
# Fallback USERPROFILE (format C:\Users\...) kalau $HOME tidak ter-set.
if [ -n "${AO_HOME:-}" ]; then
  # Override manual: set AO_HOME=/c/path/ke/home sebelum panggil sync.sh
  HOME_DIR="$AO_HOME"
elif [ -n "${HOME:-}" ] && [ "$HOME" != "/" ]; then
  HOME_DIR="$HOME"
elif [ -n "${USERPROFILE:-}" ]; then
  # Konversi C:\Users\... → /c/Users/... untuk Git Bash/MSYS.
  case "$USERPROFILE" in
    [A-Za-z]:\\*)
      _drive="$(printf '%s' "$USERPROFILE" | cut -c1 | tr 'A-Z' 'a-z')"
      _rest="$(printf '%s' "$USERPROFILE" | cut -c3- | tr '\\' '/')"
      HOME_DIR="/${_drive}/${_rest}"
      ;;
    *)
      HOME_DIR="$USERPROFILE"
      ;;
  esac
else
  echo "Tidak dapat mendeteksi HOME (set AO_HOME secara manual)." >&2
  exit 1
fi

declare -A AGENTS_DIR SKILLS_DIR
AGENTS_DIR[opencode]="$HOME_DIR/.config/opencode/agents"
SKILLS_DIR[opencode]="$HOME_DIR/.config/opencode/skills"
AGENTS_DIR[claude]="$HOME_DIR/.claude/agents"
SKILLS_DIR[claude]="$HOME_DIR/.claude/skills"
AGENTS_DIR[cursor]="$HOME_DIR/.cursor/rules/agents"
SKILLS_DIR[cursor]="$HOME_DIR/.cursor/rules/skills"

# --- Parse argumen -------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --opencode) TARGET="opencode" ;;
    --claude)   TARGET="claude" ;;
    --cursor)   TARGET="cursor" ;;
    --dry-run)  DRY_RUN=true ;;
    --status)   STATUS_ONLY=true ;;
    -h|--help)
      grep '^#' "$0" | head -n 12
      exit 0
      ;;
    *)
      echo "Argumen tidak dikenal: $arg" >&2
      exit 1
      ;;
  esac
done

# --- Fungsi bantu --------------------------------------------------
# Hitung ENTRIE top-level saja (tidak rekursif) — agents = file flat,
# skills = folder per skill. Recursive `find -type f` di platform yang
# punya nesting dalam (mis. laporan-generator) bisa menggantung/timeout.
count_entries() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

count_files() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -mindepth 1 -maxdepth 1 -type f | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

show_status() {
  echo "=== Status sinkronisasi ==="
  echo "Master : agents=$(count_files "$MASTER_DIR/agents") skill=$(count_entries "$MASTER_DIR/skills")"
  echo "OpenCode: agents=$(count_files "$HOME_DIR/.config/opencode/agents") skill=$(count_entries "$HOME_DIR/.config/opencode/skills")"
  echo "Claude  : agents=$(count_files "$HOME_DIR/.claude/agents") skill=$(count_entries "$HOME_DIR/.claude/skills")"
}

sync_dir() {
  local src="$1" dest="$2" label="$3"
  if [ ! -d "$src" ]; then
    echo "[skip] $label: master tidak ada ($src)"
    return
  fi
  # Guard: dest TIDAK boleh berada di dalam src (atau sama) — cegah cp loop.
  local src_real dest_real
  src_real="$(cd "$src" && pwd)"
  mkdir -p "$dest"
  dest_real="$(cd "$dest" && pwd)"
  case "$dest_real/" in
    "$src_real/"*)
      echo "[error] $label: tujuan ($dest_real) berada di dalam sumber ($src_real) — dibatalkan." >&2
      exit 1
      ;;
  esac
  if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] $label: $(count_entries "$src") entri → $dest"
    return
  fi
  # BACKUP dulu file yang akan ditimpa (mencegah kehilangan agent/skill lain).
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  local backup_root="${AO_BACKUP_DIR:-$HOME_DIR/.angry-orkestra/backup}"
  local backup="${backup_root}/${TARGET}_${label}-${ts}"
  mkdir -p "$backup"
  local overwritten=0
  while IFS= read -r -d '' srcfile; do
    local rel="${srcfile#./}"
    # Whitelist ekstensi + anti path traversal dari master.
    case "$rel" in
      *.md|*.yaml|*.yml) : ;;
      *) continue ;;
    esac
    case "$rel" in
      *..*|*/../*) echo "[skip] path tidak valid: $rel" >&2; continue ;;
    esac
    local destfile="$dest/$rel"
    if [ -f "$destfile" ]; then
      mkdir -p "$backup/$(dirname "$rel")"
      cp "$destfile" "$backup/$rel"
      overwritten=$((overwritten+1))
    fi
  done < <(cd "$src" && find . -type f -print0)

  # Salin (overwrite) — TANPA menghapus file lain di platform (non-destructive).
  cp -r "$src"/. "$dest"/
  if [ "$overwritten" -gt 0 ]; then
    echo "[ok] $label: $(count_entries "$src") entri → $dest (backup $overwritten file lama ke $backup)"
  else
    echo "[ok] $label: $(count_entries "$src") entri → $dest"
  fi
  # Prune: simpan maksimal 5 backup terbaru per platform+label.
  local keep=5
  while IFS= read -r -d '' old; do
    rm -rf "$old"
  done < <(find "$backup_root" -maxdepth 1 -mindepth 1 -type d -name "${TARGET}_${label}-*" -print0 \
    | sort -z | head -z -n -"$keep")
}

# --- Eksekusi ------------------------------------------------------
if [ "$STATUS_ONLY" = true ]; then
  show_status
  exit 0
fi

if [ -z "$TARGET" ]; then
  echo "Pilih platform: --opencode / --claude / --cursor (atau --status, --dry-run)" >&2
  exit 1
fi

echo "=== Sync ke $TARGET ==="
sync_dir "$MASTER_DIR/agents" "${AGENTS_DIR[$TARGET]}" "agents"
sync_dir "$MASTER_DIR/skills" "${SKILLS_DIR[$TARGET]}" "skills"
echo "Selesai."
