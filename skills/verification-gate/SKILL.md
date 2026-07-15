---
name: verification-gate
description: ALWAYS run before saying a coding task is "complete", "done", "working", or "fixed" — never claim completion without it. Runs the project's real verification commands (tests, lint, typecheck, build), separates verified facts from assumptions, appends a durable evidence record to the project ledger (.keel/verification.md), ticks the requirement checkboxes the evidence covers, and stamps the verified working-tree state that keel's stop gate checks. This is the skill the stop gate routes to when it blocks a stop. Triggers whenever code was edited, files generated or modified, a bug fixed, a refactor done, dependencies changed, database code or migrations touched, or API/frontend behavior altered.
---

# Verification Gate

## Why this exists

Claude tends to announce a coding task is done based on what the code *should* do, before
confirming it actually does. A false "complete" is expensive: the user trusts it, moves on,
and finds the breakage later.

This skill is the gate between "I changed the code" and "it's done" — and in keel 2.0 its
output is **durable evidence**: an append-only record in `.keel/verification.md`, requirement
checkboxes ticked only when a run evidenced them, and a machine fingerprint
(`.keel/state/last-verified`) that lets the stop gate prove, deterministically, whether the
current tree was ever verified. "I verified X by running Y and it passed" — written down,
with the tree state stamped — is worth far more than "this should work," and it's the only
form of verification a future session can trust.

## The core rule

Never describe a task as complete, done, fixed, or working unless verification supports that
claim. If verification was skipped, partial, or failed, say so plainly and set the status to
match. When unsure between two statuses, pick the more conservative one.

## Workflow

**1. Inspect what changed.** `git status`, `git diff` (and `--staged`). If not a git repo,
enumerate the files you touched this session and what you did to each. You cannot verify a
change you cannot name.

**2. Read the spec's open requirements.** If `.keel/spec.md` exists, its requirement
checklist is your verification target list: which of the open `R<n>` items should this run
evidence? A verification run that ignores the requirements verifies the wrong thing precisely.

**3. Identify the stack and find the real commands.** Project-specific instructions beat
generic defaults, in this order: `CLAUDE.md`/`AGENTS.md`/`README`/`CONTRIBUTING`/`docs/`;
then the config files themselves (`package.json` scripts, `Makefile`/`justfile` targets,
`pyproject.toml`, CI workflows — these list the exact commands the project gates on); then
the condensed catalog in `references/stack-commands.md`.

**4. Decide what is safe to run.**
- Safe: tests, linters, typecheckers, builds, `format --check`, dry runs, a short smoke run
  under a timeout.
- Not autonomously: anything mutating shared or production state, real migrations against a
  real database, deploys, destructive file operations, commands needing credentials you don't
  have, watchers with no timeout. When unsure, don't run it — list it under "not checked"
  with the reason.

**5. Run and capture.** Record the *exact* command and the *real* result, including key
error lines on failure. If the project declares a tool that isn't installed, run the closest
valid equivalent and record the substitution — a passing equivalent is real evidence, but it
is not the exact gate the project defined.

**6. Map each change to a check.** Dependencies changed → install resolves + build/test.
Schema/migration → dry-run or test DB + affected tests. API behavior → contract/integration
tests or typecheck + endpoint tests. Frontend → build + typecheck + lint, plus component/e2e
or a described manual check. A missing relevant check is itself a finding.

**7. Separate fact from assumption.** Verified means a command ran and you saw the result.
Everything else is an assumption and must be labeled as one.

**8. Write the ledger record** (with a ledger — the normal case):

Append to `.keel/verification.md`, using the next free `V<n>`:

```markdown
## V<n> — <YYYY-MM-DD HH:MM UTC> — commit <short-hash or "none">
- Ran: `npm test` (142 passed), `npx tsc --noEmit` (clean), `npm run lint` (clean)
- Verified: R1, R2 via test suite; R2 additionally in browser
- Assumed, not verified: mobile layout; concurrent-edit behavior
- Failed: <only if something failed — the key error lines>
```

Then **tick the requirements this run evidenced** in `.keel/spec.md` — `- [ ] R2: ...`
becomes `- [x] R2: ...  (verified: V<n>)`. Tick only what the evidence actually covers;
a requirement you reasoned about but didn't exercise stays open. Update the
`Open requirements:` and `Last verification:` lines in `.keel/digest.md`.

**9. Stamp the verified state** — after the turn's last code change, so the stamp matches
what was verified. If the stop gate's block message gave you a `bash '<path>' --record`
command, run that. Otherwise run this equivalent block (same fingerprint the gate computes —
content hash of all tracked + untracked non-ignored files, excluding `.keel/`):

```bash
mkdir -p .keel/state
files=$(git ls-files -co --exclude-standard | grep -v '^\.keel/' | sort -u \
  | while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done)
fp=$({ printf '%s\n' "$files"; [ -n "$files" ] && printf '%s\n' "$files" | git hash-object --stdin-paths; } | git hash-object --stdin)
{ printf '%s\n' "$fp"; printf 'recorded=%s commit=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$(git rev-parse --short HEAD 2>/dev/null || echo none)"; } > .keel/state/last-verified
```

(Outside a git repo, skip the stamp — the stop gate uses transcript-based detection there.)

**10. Report inline** using the format below, and decide the status. Without a ledger,
the inline report is the whole output; mention once that `/keel:init` would make it durable.

## Output format

ALWAYS produce this report before any completion claim. Keep it tight; evidence over prose.

```
## Verification Report  (recorded as V<n>)

**Changed files**
- path/to/file — what changed, in one line

**Commands run**
- `exact command` → pass / fail (exit code or short result)
  (or: none — and why)

**Requirements evidenced**
- R1 ✓ (test suite), R2 ✓ (browser) — R4 still open, not exercised

**What failed**
- ... (the actual error, briefly; omit section if nothing failed)

**What was not checked**
- ... and why (no e2e suite, requires prod DB, no credentials, out of scope)

**Remaining risks**
- ...

**Final status:** Complete / Partially complete / Not complete
```

## Deciding the final status

- **Complete** — every relevant safe check ran and passed; nothing material is left
  unverified, or the only unverified items are genuinely out of scope and stated as such.
- **Partially complete** — some checks passed but others failed, could not run, or don't
  exist; or the change can't be fully verified in this environment.
- **Not complete** — a relevant check failed in a way tied to the change, or no meaningful
  verification was possible for a change that needs it.

If "Commands run" is `none` for a behavioral change, the status cannot be Complete. If a
check failed, the record still gets written — a failed verification is evidence too, and the
requirement stays `[ ]`. Do **not** stamp `last-verified` when the status is Not complete:
the stamp asserts "this tree was verified," and a failing tree wasn't.

## Example

A bug fix in a TS/Node service. After editing:

```
## Verification Report  (recorded as V8)

**Changed files**
- src/auth/token.ts — fixed expiry comparison using seconds instead of ms

**Commands run**
- `npx tsc --noEmit` → pass
- `npm run lint` → pass
- `npm test -- src/auth` → fail (1 of 14)

**Requirements evidenced**
- R5 (expired tokens rejected) — NOT ticked: its test failed at the equal-to-expiry boundary.

**What failed**
- token.test.ts "rejects expired token": expected 401, got 200.

**What was not checked**
- Full suite (ran only src/auth); integration tests (require a running Redis).

**Remaining risks**
- Boundary case at exact expiry; other modules importing this helper not yet run.

**Final status:** Not complete
```

The honest "Not complete" is the whole point — and it's now in the ledger, so the next
session opens knowing R5 is still broken instead of trusting a transcript that scrolled away.
