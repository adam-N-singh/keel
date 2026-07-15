#!/usr/bin/env bash
# keel SessionEnd hook — mechanical session record.
#
# When a session ends in a project with a .keel/ ledger, append a small
# deterministic breadcrumb to .keel/handoffs/sessions.md: timestamp, end
# reason, git status summary, and the files this session edited (parsed from
# the transcript). No model authorship — the model is gone by SessionEnd.
# This is a breadcrumb, not a substitute for the rich model-authored note
# from /keel:agent-handoff-summary.
#
# Skipped when the session made no file edits and the worktree is clean —
# a read-only Q&A session leaves no useful trail.
#
# Portability: bash + git/grep/sed only. LF line endings.

input=$(cat)

[ -d ".keel" ] || exit 0

reason=$(printf '%s' "$input" \
  | sed -n 's/.*"reason"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
session_id=$(printf '%s' "$input" \
  | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

# Files edited this session, from the transcript (ledger writes excluded).
edited=""
transcript=$(printf '%s' "$input" \
  | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | tr '\\' '/')
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  edited=$(grep -E '"name"[[:space:]]*:[[:space:]]*"(Edit|MultiEdit|Write|NotebookEdit)"' "$transcript" 2>/dev/null \
    | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed 's/.*:[[:space:]]*"//; s/"$//' \
    | tr '\\' '/' \
    | grep -v '/\.keel/' | grep -v '^\.keel/' \
    | sort -u)
fi

# Git summary.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  dirty_count=$(git status --porcelain 2>/dev/null | grep -c .)
  if [ "$dirty_count" -eq 0 ]; then
    git_summary="branch $branch, worktree clean"
  else
    git_summary="branch $branch, $dirty_count uncommitted path(s)"
  fi
else
  git_summary="not a git repo"
fi

# Nothing happened — leave no record.
[ -z "$edited" ] && [ "${dirty_count:-0}" -eq 0 ] 2>/dev/null && exit 0

mkdir -p ".keel/handoffs"
{
  printf '\n## Session record — %s\n' "$(date -u '+%Y-%m-%d %H:%M UTC')"
  printf -- '- Session: %s (ended: %s)\n' "${session_id:-unknown}" "${reason:-unknown}"
  printf -- '- Git: %s\n' "$git_summary"
  if [ -n "$edited" ]; then
    printf -- '- Files edited this session:\n'
    printf '%s\n' "$edited" | sed 's/^/  - /'
  else
    printf -- '- No file edits recorded in the transcript.\n'
  fi
} >> ".keel/handoffs/sessions.md"

exit 0
