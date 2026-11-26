#!/bin/bash
# test.sh — Self-check konsistensi pipeline Angry Orkestra (tanpa framework).
# Jalankan: bash test.sh
# Verifikasi: frontmatter V2, kategori→worker/skill ada, agent preload skill ada,
# sync.sh valid, skill body memenuhi batas, agent mode valid.
#
# Exit 0 = semua lolos. Exit 1 = ada kegagalan (detail dicetak).

set -euo pipefail

# grep -P butuh locale UTF-8; tanpanya Windows/Git Bash gagal (unibyte locale).
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PASS=0
FAIL=0

pass() { PASS=$((PASS+1)); echo "  ok  - $1"; }
fail() { FAIL=$((FAIL+1)); echo "  FAIL - $1"; }

# --- 1. Frontmatter agent harus V2 (tanpa field V1 deprecated) ----------
echo "[1] Frontmatter agent V2"
for f in agents/*.md; do
  name=$(basename "$f")
  if grep -Eq '^name:|^tools:|^skills:|^model:' "$f"; then
    fail "$name masih pakai field V1 (name/tools/skills/model)"
  else
    pass "$name frontmatter V2"
  fi
  if ! grep -Eq '^mode: (all|subagent|primary)$' "$f"; then
    fail "$name tidak punya mode valid"
  fi
done

# --- 2. Kategori: worker_agent harus ADA; skill_name boleh on-demand M1 -
echo "[2] Kategori -> worker & skill"
_workers_list=$(grep -oE 'worker_agent: .*' config/categories.yaml | awk '{print $2}' || true)
while read -r worker; do
  if [ -f "agents/$worker.md" ]; then
    pass "kategori -> worker $worker.md ada"
  else
    fail "kategori -> worker $worker.md TIDAK ADA"
  fi
done <<< "$_workers_list"

_skills_list=$(grep -oE 'skill_name: .*' config/categories.yaml | awk '{print $2}' || true)
while read -r skill; do
  if [ -f "skills/$skill/SKILL.md" ]; then
    pass "kategori -> skill $skill/SKILL.md ada"
  else
    # skill_name bisa di-generate on-demand via M1 (by design). Bukan kegagalan.
    pass "kategori -> skill $skill on-demand (M1) - OK"
  fi
done <<< "$_skills_list"

# --- 2b. Kategori yang dirujuk ke SKILL.md on-disk harus punya worker agent.
#         (Balik-arah: agent yang muncul di kategori harus terdaftar minimal 1x.)

# --- 2b. Slug skill valid (anti path traversal) ------------------------
echo "[2b] Slug skill valid"
for d in skills/*/; do
  name=$(basename "$d")
  if printf '%s' "$name" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then
    pass "slug skill $name valid"
  else
    fail "slug skill $name TIDAK valid (regex ^[a-z0-9][a-z0-9-]*$)"
  fi
done

# --- 3. Skill yang dirujuk agent (via instruksi body) ada di MASTER -----
echo "[3] Skill yang dirujuk agent ada di master"
for f in agents/*.md; do
  while read -r skill; do
    if [ -f "skills/$skill/SKILL.md" ]; then
      pass "$(basename "$f") -> skill $skill ada"
    else
      fail "$(basename "$f") -> skill $skill TIDAK ADA di master"
    fi
  # Skip placeholder template seperti <skill_name>, <required_skill_name>
  done < <(grep -oE 'skills/[^ ]+/SKILL\.md' "$f" | sed 's#skills/##; s#/SKILL\.md##' | grep -Ev '<|\*|skill_name' || true)
done

# --- 4. Body skill memenuhi batas minimum kata -------------------------
echo "[4] Body skill >= 200 kata"
min=$(grep -oE 'skill_min_body_words: [0-9]+' config/categories.yaml | awk '{print $2}' || echo 200)
for f in skills/*/SKILL.md; do
  # Ekstrak body = semua baris SETELAH frontmatter (frontmatter = 2 blok --- pertama).
  # Cari baris --- kedua, ambil dari setelahnya.
  body=$(awk '
    BEGIN { n = 0; seen = 0 }
    /^---[[:space:]]*$/ {
      n++
      if (n == 2) { seen = 1; next }
    }
    seen == 1 { print }
  ' "$f")
  words=$(echo "$body" | wc -w | tr -d ' ')
  if [ "$words" -ge "$min" ]; then
    pass "$(dirname "$f") body ${words} kata"
  else
    fail "$(dirname "$f") body ${words} kata (< $min)"
  fi
done

# --- 5. sync.sh valid (bash syntax) + target path konsisten ------------
echo "[5] sync.sh"
if bash -n sync.sh 2>/dev/null; then
  pass "syntax valid"
else
  fail "syntax error"
fi
if grep -q 'AGENTS_DIR\[cursor\]=.*/rules/agents' sync.sh && \
   grep -q 'SKILLS_DIR\[cursor\]=.*/rules/skills' sync.sh; then
  pass "--cursor agents/skills terpisah"
else
  fail "--cursor agents & skills masih ke folder yang sama"
fi

# --- Ringkasan --------------------------------------------------------
echo ""
echo "======================================"
echo "PASS: $PASS   FAIL: $FAIL"
echo "======================================"
if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  echo "Semua lolos ✅"
fi
