#!/usr/bin/env bash
# keel SessionStart hook — the ledger's read path.
#
# - If .keel/digest.md exists: inject it (the compact ledger summary).
# - If this session start follows a compaction (source == "compact"): also
#   inject the Goal, Constraints, and Requirements sections of .keel/spec.md,
#   re-anchoring the model at exactly the moment drift happens.
# - If .keel/ exists but the digest is missing: point at /keel:context-recovery.
# - If no .keel/ ledger: fall back to the static skills index plus a pointer
#   to /keel:init, so new installs still get awareness.
#
# Portability: bash + grep/sed only. LF line endings (pinned in .gitattributes).

input=$(cat)

source=$(printf '%s' "$input" \
  | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

# Print a named section of a markdown file: the heading line plus everything
# until the next "## " heading (or EOF).
print_section() { # $1=file $2=heading text (e.g. "Requirements")
  sed -n "/^## $2/,/^## /{ /^## $2/p; /^## /!p; }" "$1"
}

if [ -d ".keel" ]; then
  if [ -f ".keel/digest.md" ]; then
    echo "# keel ledger digest (auto-injected; full ledger in .keel/)"
    echo
    cat ".keel/digest.md"
  else
    echo "keel: a .keel/ ledger exists but .keel/digest.md is missing or was never generated. Run /keel:context-recovery to rebuild it."
  fi

  if [ "$source" = "compact" ] && [ -f ".keel/spec.md" ]; then
    echo
    echo "# keel post-compaction re-anchor — the requirements below are the contract; do not drop or silently reinterpret any of them"
    echo
    print_section ".keel/spec.md" "Goal"
    print_section ".keel/spec.md" "Constraints"
    print_section ".keel/spec.md" "Requirements"
  fi
else
  # No ledger yet — static awareness index + onboarding pointer.
  script_dir=$(cd "$(dirname "$0")" && pwd)
  [ -f "$script_dir/skills-index.md" ] && cat "$script_dir/skills-index.md"
  echo
  echo "No .keel/ ledger in this project yet. Run /keel:init to scaffold one (spec, decisions, verification records, handoffs — persistent across sessions)."
fi

exit 0
