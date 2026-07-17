# Working Spec
Updated: 2026-07-16

## Goal
Ship keel 2.0 as a validated, honestly-documented Claude Code plugin: every README
claim backed by a controlled experiment, and the remaining open experiment (E1-interactive)
either executed or its claim explicitly bounded.

## Constraints
- Claims bounded by data: nothing enters the README claims section without an
  experiment behind it (the 1.0 overclaim mistake is not repeated).
- Hooks stay bash + git/grep/sed only, LF-pinned (.gitattributes) — portable, no deps.
- Gates ship opt-in; every gate outcome must leave a ledger record (skip paths included).
- No `version` field in plugin manifests — versioning is by git commit.
- The fingerprint logic in hooks/stop-gate.sh and the inline block in
  skills/verification-gate/SKILL.md step 9 must stay in sync.

## Requirements
- [ ] R1: E1-interactive executed — ≥3 runs per arm with a compaction confirmed in each (grade.js Compactions ≥ 1), graded and analyzed
- [ ] R2: README drift claim resolved from R1's data — upgraded with numbers, or explicitly bounded as unsupported
- [ ] R3: RESEARCH.md publish decision made and recorded in decisions.md
- [ ] R4: Haiku-floor test (RESEARCH §7) either run via the eruns harness or explicitly dropped, recorded in decisions.md

## Assumptions
- The eruns harness (skilltests/eruns/) remains the measurement instrument for R1;
  only the launch must be interactive.

## Out of scope
- New skills or hooks beyond the shipped seven + four (PreCompact stays reserved
  until evidence demands it).
- Marketplace promotion / announcement mechanics (Adam's call, not a repo task).

## Risks
- E1-interactive requires sustained interactive terminal time; if compaction proves
  hard to trigger even interactively, the drift claim stays permanently bounded —
  acceptable, but decide explicitly (feeds R2).
