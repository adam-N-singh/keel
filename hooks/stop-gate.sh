#!/usr/bin/env bash
# keel Stop hook: opt-in verification gate. When the project contains a
# .claude/keel-stop-gate marker file and the git worktree has uncommitted
# changes, block the first stop of a turn and tell Claude to run
# keel:verification-gate before finishing.
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

# Only meaningful inside a git repo with uncommitted changes.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -n "$(git status --porcelain 2>/dev/null)" ] || exit 0

cat <<'EOF'
{"decision": "block", "reason": "keel stop gate: this session has uncommitted code changes and is about to finish. Invoke keel:verification-gate — find and run the project's real verification commands (tests, lint, typecheck, build) and report verified facts vs. assumptions — before concluding. If verification already ran this turn and was reported, finish normally."}
EOF
exit 0
