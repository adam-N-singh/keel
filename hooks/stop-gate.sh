#!/usr/bin/env bash
# keel Stop hook: opt-in verification gate. When the project contains a
# .claude/keel-stop-gate marker file and this session changed code, block
# the first stop of a turn and tell Claude to run keel:verification-gate
# before finishing.
#
# "Changed code" is detected two ways:
#   - inside a git repo: uncommitted changes in the worktree
#   - outside git: any file-modifying tool call (Edit/Write/MultiEdit/
#     NotebookEdit) recorded in the session transcript. Coarser than the
#     git check — it stays "dirty" for the rest of the session, so each
#     later turn gets one block-and-justify pass rather than a clean exit.
#
# Opt in per project:   touch .claude/keel-stop-gate
# Opt out:              delete that file

input=$(cat)

# Loop prevention: if this stop was already blocked once, let it through.
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Opt-in marker required.
[ -f ".claude/keel-stop-gate" ] || exit 0

dirty=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  [ -n "$(git status --porcelain 2>/dev/null)" ] && dirty=1
else
  # No git: check the transcript for file-modifying tool calls. The path
  # arrives JSON-escaped (backslashes doubled on Windows); forward slashes
  # are safe on every platform, and Windows collapses the duplicates.
  transcript=$(printf '%s' "$input" \
    | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | tr '\\' '/')
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    grep -qE '"name"[[:space:]]*:[[:space:]]*"(Edit|MultiEdit|Write|NotebookEdit)"' "$transcript" && dirty=1
  fi
fi

[ -n "$dirty" ] || exit 0

cat <<'EOF'
{"decision": "block", "reason": "keel stop gate: this session has unverified code changes and is about to finish. Invoke keel:verification-gate — find and run the project's real verification commands (tests, lint, typecheck, build) and report verified facts vs. assumptions — before concluding. If verification already ran this turn and was reported, finish normally."}
EOF
exit 0
