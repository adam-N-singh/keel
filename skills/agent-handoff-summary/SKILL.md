---
name: agent-handoff-summary
description: "Write a rich handoff note into the project ledger (.keel/handoffs/) WHEN wrapping up, pausing, or passing off work — triggers on 'write a handoff', 'hand this off', 'summarize this for the next session or agent', 'document where we are', 'I am low on context, wrap up', 'pass this to Codex/Cursor', or 'session summary'. Also reach for it proactively at the end of any meaningful chunk of work — substantial coding, debugging, a failed or abandoned attempt, an architecture decision — since those are the moments where lost context is most expensive. Captures goal, changes, decisions, assumptions, verification status, dead ends (which also go to .keel/deadends.md), warnings, and the best next step; updates the digest so the very next session start carries the pointer."
---

# Agent Handoff Summary

## What this is for

A coding session accumulates context that lives nowhere except the conversation: why a
library was chosen, which approach already failed, what got tested versus what just *looks*
done, the one command that quietly resets the database. When the next worker — another
Claude, a Codex or Cursor agent, or a human — opens a fresh window, all of that is gone.

This skill writes that context into the ledger, where the next session's start hook will
surface it. The goal: **the next worker should be able to make the right next move without
asking a single question.**

The single most important principle: **write down what cannot be cheaply rediscovered.**
The next worker can read the code; they cannot read your mind. The high-value content is the
*why* behind changes, the approaches that didn't work, the things you assumed without
verifying, and the landmines. Spend your effort there, not on restating what `git diff`
already shows.

Note: keel's SessionEnd hook writes a small *mechanical* record (timestamp, git summary,
files touched) automatically. That is a breadcrumb, not a handoff — it cannot capture the
why, the dead ends, or the warnings. This skill is the rich half of the pair.

## Gather the material from the session, not from the user

Mine the conversation yourself: the request, the files you read and edited, the commands you
ran, the errors you hit, the decisions you talked through. Cross-check the ledger — `spec.md`
for requirement status, `verification.md` for what was actually evidenced, `decisions.md` for
choices already recorded (reference them by `D`-ID rather than restating).

If the session is a continuation and some context predates it, mark that section "carried
over from a prior session — original framing not in this transcript" rather than stalling.

## Output format

```markdown
# Agent Handoff — <YYYY-MM-DD> — <short title>

## Original request
## Current goal
## What changed
## Files touched
## Decisions made
## Assumptions
## Commands run
## Verification status
## Problems encountered
## Unfinished work
## Warnings for next agent
## Recommended next step
```

## How to fill each section well

**Original request** — what the user actually asked for, in their framing, before the work
reshaped it. If the request evolved mid-session, capture the original and note the shift.

**Current goal** — the immediate objective *right now*, often narrower than the original
request. The first thing the next worker needs.

**What changed** — behavior and intent, not line counts. "Switched session storage from
localStorage to httpOnly cookies so tokens survive a refresh" beats "edited auth.ts".

**Files touched** — created/modified/deleted, each with a one-line note on what and why.
Mark new files and deletions explicitly. Skip files you only read.

**Decisions made** — non-obvious choices as "chose X over Y because Z", including trade-offs
knowingly accepted. Cite ledger `D`-IDs where they exist. This section stops the next worker
from relitigating settled questions or undoing deliberate choices.

**Assumptions** — things treated as true without confirming, each specific enough to check.
Bugs love to hide exactly here.

**Commands run** — what matters for reproducing state or re-checking work: installs, builds,
migrations, test runs, seeds. Note directory- or env-specific commands. Omit incidental
navigation.

**Verification status** — scrupulously honest, anchored to the ledger: cite the `V` record
if one was written this session ("V8: tests+lint+typecheck green; prod callback NOT tested").
If nothing was verified, say "unverified" plainly — that is useful information; a vague
"should be working" is not.

**Problems encountered** — failed attempts and dead ends with enough *why* that nobody
repeats them. Paste the key error when diagnostic.

**Unfinished work** — the actual remaining steps, not "finish the feature". A checklist is fine.

**Warnings for next agent** — the landmines: fragile areas, things that look wrong but are
intentional, destructive commands to avoid, environment quirks. High-signal, low-volume.

**Recommended next step** — the single best action, concrete enough to start immediately:
the file, the function, the pattern to follow. One clear move beats a menu.

If a section is genuinely empty, keep the heading with an explicit "None — implementation
was straightforward." An omitted heading makes the next worker wonder if it was forgotten.

## Writing to the ledger

**With a ledger** (the normal case):

1. Write the note to `.keel/handoffs/YYYY-MM-DD-<slug>.md` (slug from the current goal,
   e.g. `2026-07-15-settlement-rounding.md`; use the actual date). Show the full note in
   the conversation too — the user should read it now, not archaeologize it later.
2. If *Problems encountered* contains a genuinely abandoned approach, append it to
   `.keel/deadends.md` (`## <date> — <approach>` + 1–2 lines of why) so it warns future
   sessions even when nobody reads this specific handoff.
3. Update `.keel/digest.md`: set the `Last handoff:` line to this file plus a one-line
   summary, and refresh anything the session changed (phase, open requirements). Respect
   the 600-token cap — drop from the digest's tail, never from its goal/requirements head.

**Without a ledger**: present the note inline; if a legacy `docs/handoffs/` directory
exists, offer to save it there. Mention once that `/keel:init` would make handoffs
automatic ledger citizens.

## Match the note to the session

Scale the handoff to the work: a twenty-minute bug fix gets a tight note; a multi-hour
architecture session gets a fuller one. Lead with what the next worker reads first —
current goal, warnings, recommended next step. Honesty about what's empty is itself signal.
