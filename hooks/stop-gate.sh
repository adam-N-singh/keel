#!/usr/bin/env bash
# keel Stop hook v2 — verification-freshness gate.
#
# Opt-in via GATE_STOP_VERIFY=1 in .keel/config (the legacy 1.0 marker
# .claude/keel-stop-gate is still honored). When enabled, a turn in which this
# session edited project files may not finish while the working tree differs
# from the state recorded at the last verification (.keel/state/last-verified).
# Freshness, not dirtiness: committing changes does not make you "verified",
# and verified-then-committed content does not re-block.
#
# The fingerprint is a content hash of every tracked + untracked (non-ignored)
# file, EXCLUDING .keel/ itself — ledger writes never make the tree "unverified",
# and commits of already-verified content don't change it.
#
#   fingerprint = hash( sorted file list + per-file content hashes )
#
# Recording: `bash <this script> --record` writes the current fingerprint to
# .keel/state/last-verified. The verification-gate skill runs it (an equivalent
# inline block is quoted there — keep the two in sync) as its final step, after
# all ledger writes.
#
# Outside git there is no fingerprint; the gate falls back to 1.0 behavior:
# one block per turn while the session has file edits (loop-safe via
# stop_hook_active).
#
# Portability: bash + git/grep/sed only. LF line endings.

# --- shared fingerprint (keep in sync with skills/verification-gate/SKILL.md) ---
keel_fingerprint() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    files=$(git ls-files -co --exclude-standard 2>/dev/null \
      | grep -v '^\.keel/' | sort -u \
      | while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done)
    {
      printf '%s\n' "$files"
      [ -n "$files" ] && printf '%s\n' "$files" | git hash-object --stdin-paths 2>/dev/null
    } | git hash-object --stdin 2>/dev/null
  else
    echo "no-git"
  fi
}

# --- record mode (invoked by the verification-gate skill, not as a hook) ---
if [ "$1" = "--record" ]; then
  mkdir -p ".keel/state"
  fp=$(keel_fingerprint)
  commit=$(git rev-parse --short HEAD 2>/dev/null || echo none)
  {
    printf '%s\n' "$fp"
    printf 'recorded=%s commit=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$commit"
  } > ".keel/state/last-verified"
  echo "keel: verified state recorded ($fp, commit $commit)"
  exit 0
fi

input=$(cat)

# Loop prevention: if this stop was already blocked once, let it through.
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Opt-in required: .keel/config flag, or the legacy 1.0 marker.
enabled=""
[ -f ".keel/config" ] && grep -q '^GATE_STOP_VERIFY=1' ".keel/config" && enabled=1
[ -f ".claude/keel-stop-gate" ] && enabled=1
[ -n "$enabled" ] || exit 0

# Did THIS session edit project files (ledger writes excluded)? The transcript
# path arrives JSON-escaped (backslashes doubled on Windows); forward slashes
# are safe on every platform.
session_edited=""
transcript=$(printf '%s' "$input" \
  | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | tr '\\' '/')
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  edits=$(grep -E '"name"[[:space:]]*:[[:space:]]*"(Edit|MultiEdit|Write|NotebookEdit)"' "$transcript" 2>/dev/null \
    | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed 's/.*:[[:space:]]*"//; s/"$//' \
    | tr '\\' '/' \
    | grep -v '/\.keel/' | grep -v '^\.keel/')
  [ -n "$edits" ] && session_edited=1
fi
[ -n "$session_edited" ] || exit 0

self=$(printf '%s' "$0" | tr '\\' '/')

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  current=$(keel_fingerprint)
  recorded=$(sed -n '1p' ".keel/state/last-verified" 2>/dev/null)
  [ -n "$current" ] && [ "$current" = "$recorded" ] && exit 0
  cat <<EOF
{"decision": "block", "reason": "keel stop gate: this session edited files and the verification record is stale (the working tree no longer matches .keel/state/last-verified). Invoke keel:verification-gate — run the project's real checks (tests, lint, typecheck, build), append the record to .keel/verification.md, update any requirement checkboxes it evidenced — and as the final step stamp the verified state by running: bash '$self' --record. If a verification record covering the current tree was already written this turn, run only the --record command and finish."}
EOF
else
  cat <<'EOF'
{"decision": "block", "reason": "keel stop gate: this session has unverified code changes and is about to finish. Invoke keel:verification-gate — find and run the project's real verification commands (tests, lint, typecheck, build), append the record to .keel/verification.md, and report verified facts vs. assumptions — before concluding. If verification already ran this turn and was recorded, finish normally."}
EOF
fi
exit 0
