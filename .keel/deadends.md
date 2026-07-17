# Dead ends

## 2026-07-15 — Nested `claude -p` from inside a Claude session
Fails auth ("Not logged in") no matter what: env-scrubbing all CLAUDE*/ANTHROPIC*
vars, sandbox-off, profile-less shells. Do not retry; launch test runs from a real
terminal. (Plugin *management* commands work fine in-session.)

## 2026-07-15 — Plain `bash script.sh` from PowerShell
Resolves to WSL's System32 bash where Windows claude/config don't exist. Use the
.cmd wrappers (explicit Git Bash path) or run from Git Bash. Runners now refuse
non-MINGW shells.

## 2026-07-16 — `/compact` as a headless prompt
`claude -p "/compact" --resume <sid>` does NOT execute the slash command — the model
receives it as literal text. Compaction cannot be scripted this way; E1 needs an
interactive session (or organic context overflow).

## 2026-07-14 — Soft-visibility interventions (1.0)
Reflowed descriptions, session-start index hardening, invoke-by-default framing,
UserPromptSubmit keyword nudge: all verifiably reached the model; all produced zero
invocations. The nudge also false-positived on pasted text. Don't rebuild any of it.

## 2026-07-16 — `spawnSync(..., {shell: true})` with quoted `node -e` scripts on Windows
cmd.exe mangles the quotes — grade.js C6 false-failed all six arms. Use shell:false
for node invocations; shell only where .cmd shims require it (npm).
