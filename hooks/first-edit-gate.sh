#!/usr/bin/env bash
# keel PreToolUse hook (Edit|Write|MultiEdit|NotebookEdit) — first-edit gate.
#
# Opt-in via GATE_FIRST_EDIT=1 in .keel/config. When enabled, the session's
# first file edit is blocked unless .keel/spec.md exists and contains at least
# one requirement line. The deny reason routes the model to
# /keel:agent-spec-builder, with a recorded-skip escape hatch (append a skip
# entry to .keel/decisions.md).
#
# The gate blocks ONCE per session: a session-scoped marker in .keel/state/
# prevents re-blocking, so an escape hatch that leaves a record always beats a
# gate people disable. Edits inside .keel/ itself are always allowed (writing
# the spec must not be blocked by the gate that asks for it).
#
# Portability: bash + grep/sed only. LF line endings.

input=$(cat)

# Ledger + opt-in required.
[ -f ".keel/config" ] || exit 0
grep -q '^GATE_FIRST_EDIT=1' ".keel/config" || exit 0

# Always allow ledger writes (spec.md, decisions.md, digest, ...).
file_path=$(printf '%s' "$input" \
  | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | tr '\\' '/' | tr -s '/')
case "$file_path" in
  .keel/*|*/.keel/*) exit 0 ;;
esac

# A spec with at least one requirement satisfies the gate.
if [ -f ".keel/spec.md" ] \
  && grep -qE '^[[:space:]]*- \[[ x~]\] R[0-9]+:' ".keel/spec.md"; then
  exit 0
fi

# Block once per session, then stand down.
session_id=$(printf '%s' "$input" \
  | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -n "$session_id" ] || session_id="unknown"
marker=".keel/state/first-edit-gate.$session_id"
[ -f "$marker" ] && exit 0
mkdir -p ".keel/state" && : > "$marker"

cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "keel first-edit gate: no Working Spec with requirements exists yet (.keel/spec.md). Invoke keel:agent-spec-builder to write one before editing files — or, if a spec is genuinely unnecessary here, append a skip entry to .keel/decisions.md ('## D<n> — <date> — first-edit gate skipped' plus a one-line reason) and retry the edit. This gate blocks only once per session."}}
EOF
exit 0
