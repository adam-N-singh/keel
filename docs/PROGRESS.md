# keel 2.0 — Progress & Handoff

**Date:** 2026-07-15. **Written for:** any agent (or human) picking this up cold.
**Read first:** [DESIGN.md](../DESIGN.md) (the keel 2.0 design + experiment plan §7),
[RESEARCH.md](RESEARCH.md) (the 1.0 falsification that motivated 2.0),
[LEDGER.md](LEDGER.md) (ledger format spec — canonical; hooks parse these shapes).

---

## 1. Where things stand, in one paragraph

keel 2.0 ("the project flight recorder") is fully implemented, shipped, and installed:
persistent `.keel/` ledger + four deterministic hooks + all seven skills rewritten as
ledger interfaces. Phase-0 mechanics all passed live (including the first organic keel
skill invocations ever recorded). A quick E-run subset closed E3 (stop gate in anger)
and produced one directional E2 pair; findings led to two shipped fixes. The E-run
harness was then reset for a uniform full run. **The single remaining blocking task:
Adam launches `.\runner.cmd`; then grade the results and update README claims per
DESIGN §7's kill criteria.**

## 2. Shipped commits (adam-N-singh/keel, main — all pushed, plugin installed at user scope)

| Commit | What |
| --- | --- |
| `6bc1618` | Full 2.0 implementation: docs/LEDGER.md; hooks session-start.sh (digest injection + post-compaction re-anchor), first-edit-gate.sh (opt-in PreToolUse), stop-gate.sh v2 (content-fingerprint freshness, `--record` mode, non-git fallback), session-end.sh (mechanical records); all six skill bodies rewritten as ledger read/write interfaces + new `/keel:init`; README/manifests repositioned. Every hook bash-level tested pre-ship. |
| `703b618` | Phase-0 fixes: `tr -s '/'` on transcript-derived paths (JSON-escaped `\\` became `//`), ASCII session-record headings (PS 5.1 Get-Content mojibake). Phase-0 results recorded in DESIGN.md status block. |
| `274696b` | E3 fix: stop gate block reason now offers a **recorded-skip** path (append a `## D<n>` skip entry to decisions.md) — DESIGN §6 promised every gate an escape hatch that leaves a record; the stop gate lacked one and E3 proved it mattered. |

Plugin state: `keel@keel` at user scope = `274696bfec0f`. Update loop after any repo change:
`claude plugin marketplace update keel && claude plugin update keel@keel` (works from
inside a Claude session; actual test RUNS do not — see §6).

## 3. Test results so far (all transcript-verified, not model self-report)

### Phase-0 (interactive, rig: `skilltests\phase0`, runbook+results: `skilltests\PHASE0-RUNBOOK.md`)
- **Compact re-anchor works**: `SessionStart(source=compact)` fires; Goal/Constraints/Requirements
  injected; model recited all requirements post-`/compact` with zero file reads. Headline mechanism confirmed.
- **First-edit gate works**: deny reason reached the model verbatim; blocked exactly once;
  model invoked `keel:agent-spec-builder` (with `keel:verification-gate`, the first organic
  keel invocations across ALL experiments — 1.0 had zero in four runs).
- **Stop gate pass-path works**: model verified preemptively every turn (deterrence);
  stamp on disk byte-identical to `--record` output (skill-inline block parity held).
- Hooks-approval prompt never appeared on plugin update, but hooks ran (approval persisted).

### Quick E-runs (headless, 2026-07-15; archive: `skilltests\eruns\results\REPORT-quickrun-2026-07-15.md`)
- **E3 CLOSED (n=3)**: user prompt explicitly forbade verification → gate blocked 3/3 →
  model sided with the user 3/3: no verification, no record, exit via `stop_hook_active`
  loop guard — transparently flagged in its reply. Conclusion: the gate cannot coerce
  against an explicit user countermand; its realistic value is deterrence + recorded
  exceptions. The missing recorded-skip hatch was fixed same day (`274696b`).
- **E2 directional (n=1 pair, leaky seed — superseded)**: both arms functionally equivalent;
  ledger arm ran the full loop organically (invoked verification-gate, wrote V2, ticked
  R5–R8, stamped) at +$0.51/+0.9 min vs control = cost of the paper trail; no orientation
  win. Caveat discovered: the seed's cli.js comment/usage string leaked the remaining
  work to the control arm → seeds regenerated leak-free, pair reset for uniform re-run.

## 4. The E-run harness (`C:\Users\adams\projects\Personal\skilltests\eruns\`)

Built per DESIGN §7, n=3 per arm. Current state: **fully reset and armed** — all 15
projects freshly seeded (E2 leak-free, git histories clean), `results/` holds only the
quick-run archive. The full runner executes everything: 6×E1 (3 turns each: build →
`/compact` → extend), 6×E2 continuations, 3×E3.

- `setup.sh` — regenerates all arm projects deterministically (idempotent; already run).
- `runner.sh` / `runner.cmd` — full set, sequential, resumable (skips tags with existing
  `results/<tag>.json`), `--dangerously-skip-permissions`, captures per-run JSON + timing,
  commits project state after each turn.
- `quick-runner.sh` / `quick-runner.cmd` — 30-min subset (already consumed; superseded by reset).
- `grade.js` — objective grader → `results/REPORT.md`: E1 runs 10 constraint checks by
  executing the built CLIs; E2 counts tool calls before first non-`.keel` edit from
  transcripts; E3 checks blocks / new V records / stamp / **Skip-recorded D entries**
  (column added for the re-run against `274696b`); E4 aggregates cost per arm.
- `ERUNS-README.md` — protocol, arms table, known unknowns, §7 kill criteria.

Known unknowns the full run will answer empirically: does `/compact` execute under
`-p --resume` (if not, E1 shows Compactions=0 and degrades to a long-continuation drift
test — still reportable, weaker); do PreToolUse denies hold under
`--dangerously-skip-permissions` (grader's firstEditDenies metric answers it).

## 5. Remaining tasks, in order

**UPDATE 2026-07-16: the full E-run happened and was graded.** Full analysis:
`skilltests/eruns/results/ANALYSIS-2026-07-16.md`; verdict recorded in DESIGN.md
status block; README claims upgraded (E2 continuity 3/3-vs-0/3 claimed with data;
gate contract = deterrence + recorded exceptions, validated n=3; E4 costs
published; ledger SURVIVES the §7 kill criteria on E2's outcome delta).

Remaining:

1. **E1-interactive** — the one experiment left. Headless `/compact` under
   `-p --resume` does NOT execute (model sees literal text), so no E1 run ever
   compacted and the drift-outcome delta is still unmeasured (mechanism proven in
   Phase-0). Protocol: re-run e1 A/B pairs from an interactive terminal, issuing
   `/compact` mid-build (or pad the build to overflow context organically), then
   `node grade.js` — the Compactions column validates each run. Seeds regenerate
   via `setup.sh`; clear the e1 tags in `results/` first.
2. Deferred/optional: strip DEP0190 warning in grade.js (cosmetic); consider a
   PreCompact snapshot hook (reserved in DESIGN §4, so far unnecessary);
   Haiku-floor test from RESEARCH §7 (never run); publish decision on RESEARCH.md
   (Adam decides); consider whether E2's headline result belongs in the README
   intro rather than the claims section (marketing call — Adam's).

## 6. Hard-won environment knowledge (do not re-learn these)

- **Nested `claude -p` fails auth** ("Not logged in") from inside any Claude session —
  env-scrubbing and sandbox-off do NOT fix it (RESEARCH §6.5, reconfirmed twice). Test
  runs must launch from Adam's terminal. Plugin *management* commands work fine in-session.
- **WSL trap**: from PowerShell, plain `bash` = `System32\bash.exe` (WSL) where Windows
  claude/config don't exist. Both runners refuse non-MINGW shells; the `.cmd` wrappers
  invoke `C:\Program Files\Git\bin\bash.exe` explicitly. Runners also self-resolve the
  CLI (PATH → `~/.local/bin/claude.exe`), overridable via `CLAUDE_BIN`.
- **Transcripts** live at `~\.claude\projects\<slug>\*.jsonl`, slug = absolute path with
  `[:\\/]` → `-`. Grep patterns: digest `keel ledger digest`; re-anchor
  `post-compaction re-anchor`; deny `no Working Spec with requirements exists yet`;
  stop-block `keel stop gate`; invocations `'"skill":\s*"keel:'`.
- **Fingerprint parity**: stop-gate.sh's `keel_fingerprint()` and the inline block in
  `skills/verification-gate/SKILL.md` step 9 must stay in sync (content hash over sorted
  tracked+untracked non-ignored files, `.keel/` excluded). Verified identical in Phase-0.
- Windows PowerShell 5.1 `Get-Content` misrenders UTF-8 punctuation — hook-written ledger
  records use ASCII `--` in headings for that reason.
- `.gitattributes` pins LF for `.sh/.json/.md` — hooks break on CRLF clones without it.
- Memory index for this project: `~\.claude\projects\C--Users-adams-projects-Personal-keel\memory\`
  (`keel-skill-origins.md` carries this history) — but this doc is self-contained on purpose.

## 7. File map (what's where)

| Path | What |
| --- | --- |
| `keel/` repo | plugin source: `.claude-plugin/`, `hooks/`, `skills/`, `docs/` |
| `keel/DESIGN.md` | 2.0 design; status block = running results log |
| `keel/docs/RESEARCH.md` | 1.0 falsification record (historical, do not edit) |
| `keel/docs/LEDGER.md` | ledger format spec (canonical) |
| `skilltests/phase0/` | Phase-0 rig (used; results in its ledger + runbook) |
| `skilltests/PHASE0-RUNBOOK.md` | Phase-0 protocol + filled results table (kept OUTSIDE the rig to avoid contaminating test models — same rule for ERUNS-README vs the arm dirs) |
| `skilltests/eruns/` | E-run harness (armed, awaiting `.\runner.cmd`) |
| `skilltests/splitfair*` | 1.0-era test arms (historical) |
