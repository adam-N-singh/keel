#!/usr/bin/env bash
# keel UserPromptSubmit hook: inject a one-line discipline nudge when the
# prompt looks like a coding task. Emits nothing on non-matching prompts.
# Stdout from a UserPromptSubmit hook is added to Claude's context.

input=$(cat)

# Match task-shaped verbs in the submitted prompt. Case-insensitive,
# word-boundary anchored to keep false positives low.
if printf '%s' "$input" | grep -qiE '\b(build|implement|create|add|refactor|redesign|rewrite|fix|debug|migrate|integrate|ship|deploy)\b'; then
  echo "keel: this looks like a coding task. If the request is vague or spans multiple files, invoke keel:agent-spec-builder (spec) and keel:implementation-planner (phases) BEFORE editing; invoke keel:verification-gate before claiming anything is complete, done, working, or fixed."
fi

exit 0
