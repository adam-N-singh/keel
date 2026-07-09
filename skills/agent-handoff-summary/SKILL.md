---
name: agent-handoff-summary
description: "Write a handoff note WHEN wrapping up, pausing, or passing off work — triggers on 'write a handoff', 'create a handoff note', 'hand this off', 'summarize this for the next session or agent', 'document where we are', 'I am low on context, wrap up', 'pass this to Codex/Cursor', or 'session summary' — so whoever picks up next (a future Claude session, a Codex or Cursor agent, or a human developer) can continue without rediscovering everything. Also reach for it proactively at the end of any meaningful chunk of work — substantial coding, debugging, refactoring, planning, a failed or abandoned implementation attempt, an architecture decision, or verification work — since those are the moments where lost context is most expensive. The note captures the original request, current goal, what changed, files touched, decisions and their reasoning, assumptions, commands run, verification status, dead ends, unfinished work, warnings, and the best next step."
---

# Agent Handoff Summary

## What this is for

A coding session accumulates a huge amount of context that lives nowhere except this conversation: why a library was chosen, which approach already failed, what got tested versus what just *looks* done, the one command that quietly resets the database. When the next worker — another Claude, a Codex or Cursor agent, or a human — opens a fresh window, all of that is gone. They re-read the code, re-derive the decisions, and often re-make the same mistakes.

This skill produces a handoff note that carries the expensive, non-recoverable context forward. The goal is simple: **the next worker should be able to make the right next move without asking you a single question.**

The single most important principle: **write down what cannot be cheaply rediscovered.** The next worker can read the code themselves; they cannot read your mind. So the high-value content is the *why* behind changes, the approaches that didn't work, the things you assumed without verifying, and the landmines. Spend your effort there, not on restating what a `git diff` would already show.

## Gather the material from the session, not from the user

Default to mining the conversation yourself. You have the full session: the user's request, the files you read and edited, the commands you ran, the errors you hit, the decisions you talked through. Reconstruct the handoff from that record rather than interrogating the user.

If the session is a *continuation* and some context predates it (e.g. the original request happened in an earlier window), and you genuinely can't recover it, ask one focused question or mark that section "carried over from a prior session — original framing not in this transcript." Don't stall the whole handoff waiting on the user.

## Output format

Produce the note using exactly this structure, as Markdown. Keep the headings and their order even when a section is empty (see "When a section is empty" below).

```markdown
# Agent Handoff

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

**Original request** — What the user actually asked for, in their framing, before the work reshaped it. This anchors the next worker to the real intent so they don't optimize a sub-task and lose the plot. If the request evolved mid-session, capture the original here and note that it shifted.

**Current goal** — The immediate objective *right now*, which is often narrower than the original request ("get the login redirect working" rather than "build auth"). This is the first thing the next worker needs: what are we actually trying to do at this moment.

**What changed** — How the system behaves or is structured differently because of this session. Describe the change in terms of behavior and intent, not line counts. "Switched session storage from localStorage to httpOnly cookies so tokens survive a refresh" beats "edited auth.ts". A `git diff` shows the lines; only you can explain what they accomplish.

**Files touched** — A concrete list of files created, modified, or deleted, each with a one-line note on *what* changed in it and *why it matters*. This is the map the next worker uses to orient. Mark new files and deletions explicitly. Skip files you only read.

**Decisions made** — The non-obvious choices and the reasoning behind them, ideally as "chose X over Y because Z." This is often the highest-value section: it stops the next worker from relitigating a settled question or quietly undoing a deliberate choice because they didn't know it was deliberate. Include trade-offs you knowingly accepted.

**Assumptions** — Things you treated as true without fully confirming. "Assumed the upstream API returns ISO-8601 timestamps — not verified against a live response." Bugs love to hide exactly here, so naming the assumptions tells the next worker where to look first when something breaks.

**Commands run** — The commands that matter for reproducing state or re-checking work: installs, builds, migrations, test runs, seed scripts, env setup. Include enough that the next worker can recreate your environment and re-run your checks. Omit incidental navigation (`ls`, `cd`). Note any command that must be run in a specific directory or with specific env vars.

**Verification status** — Be scrupulously honest here, because this is where false confidence does the most damage. Separate what you actually verified (tests passed, build succeeded, you observed the feature working) from what you *expect* to work but did not check. "Unit tests pass; the OAuth redirect was confirmed manually in dev; the production callback URL was NOT tested" is a good entry. If you verified nothing, say so plainly — "unverified" is useful information, a vague "should be working" is not.

**Problems encountered** — Failed attempts, dead ends, and approaches you abandoned, with enough of the *why* that the next worker won't waste time repeating them. Paste the key error message when it's diagnostic. "Tried connection pooling via PgBouncer in transaction mode — broke prepared statements, reverted" can save the next worker an afternoon.

**Unfinished work** — What's left, specifically. Not "finish the feature" but the actual remaining steps: "wire the reset-password form to the new endpoint; add the rate-limit middleware; the email template still has placeholder copy." A checklist is fine.

**Warnings for next agent** — The landmines. Fragile areas, things that look wrong but are intentional, destructive commands to avoid, environment quirks, work-in-progress that's committed but broken. "Don't run `prisma migrate reset` — it wipes the seeded test accounts the e2e suite depends on." High-signal, low-volume. If there's one section that prevents disaster, it's this one.

**Recommended next step** — The single best action to take next, concrete enough to start immediately. Point at the file, the function, the pattern to follow. "Open `app/api/auth/callback/route.ts` and handle the `error` query param the same way `login/route.ts` already does; that's what's blocking the redirect." One clear next move beats a menu of options.

## When a section is empty

If a section genuinely has no content — no failed attempts, no assumptions — keep the heading and write a short explicit note like "None — implementation was straightforward" or "None worth flagging." An omitted section makes the next worker wonder whether it was forgotten; an explicit "none" tells them it was considered and is clear. Don't pad a thin section to look fuller; honesty about what's empty is itself signal.

## Match the note to the session

Scale the handoff to the work. A twenty-minute bug fix gets a tight note; a multi-hour architecture session gets a fuller one. Don't inflate a small session with ceremony, and don't compress a large one into something lossy. Lead with what the next worker needs first — usually current goal, warnings, and recommended next step are what they read before touching anything.

## Saving the handoff

After drafting the note, check whether a `docs/handoffs/` directory exists in the project (e.g. `ls docs/handoffs/`). 

- **If it exists**, offer to save the note there as a dated Markdown file — `docs/handoffs/YYYY-MM-DD-<short-slug>.md`, where the slug comes from the current goal (e.g. `2025-06-15-supabase-auth-redirect.md`). Use the actual current date. Write the file only after the user agrees, since it's a change to their repo.
- **If it doesn't exist**, present the handoff inline in the conversation. You can mention once that creating a `docs/handoffs/` folder would let you save these going forward — but don't create the directory unprompted.

Either way, always show the full note in the conversation so the user can read it immediately.

## A worked example

This is the target quality and density — concrete, honest, and skimmable.

```markdown
# Agent Handoff

## Original request
"Users get logged out every time they refresh the page — fix it." Later clarified
that it only happens in production, not local dev.

## Current goal
Make the auth session survive a page refresh in the deployed Vercel environment.

## What changed
Moved the Supabase session from client-side localStorage to httpOnly cookies via
the `@supabase/ssr` package, so the server can read the session on the initial
request instead of the client hydrating it after load. This is the change that
should fix the refresh logout.

## Files touched
- `lib/supabase/server.ts` (new) — server client that reads/writes auth cookies.
- `lib/supabase/client.ts` (modified) — switched from `createClient` to
  `createBrowserClient` so client and server share the cookie-based session.
- `middleware.ts` (new) — refreshes the session cookie on every request; without
  this the cookie goes stale after the access token expires.
- `lib/supabase/legacy.ts` (deleted) — old localStorage-based client, fully replaced.

## Decisions made
- Chose `@supabase/ssr` over hand-rolling cookie handling because Supabase
  deprecated the old auth-helpers and ssr is the supported path for Next.js App Router.
- Kept middleware matching broad (all routes except static assets) rather than
  per-route, trading a little overhead for not silently missing a protected route later.

## Assumptions
- Assumed all auth reads go through the two client factories above. If any component
  still imports the old client directly, it will break — grep for `createClient` to confirm.
- Assumed the Vercel project has `SUPABASE_URL` and the anon key set; verified the
  names locally but did NOT confirm they're present in the production environment.

## Commands run
- `npm install @supabase/ssr` (removed `@supabase/auth-helpers-nextjs`)
- `npm run dev` — verified login + refresh locally
- `npm run build` — passed

## Verification status
- Local dev: login and refresh confirmed working manually.
- Build: passes clean.
- Production: NOT tested. The original bug only reproduces in prod, so this is the
  critical gap — the fix is unverified against the actual failure condition.

## Problems encountered
- First tried just setting `persistSession: true` on the existing localStorage
  client — no effect, because the server never sees localStorage on the initial
  render. That's what pointed to needing cookie-based SSR auth.

## Unfinished work
- Deploy to a Vercel preview and confirm refresh no longer logs the user out.
- Confirm the two env vars exist in the production environment.
- Remove the now-unused `auth-helpers` types still imported in `types/auth.ts`.

## Warnings for next agent
- `middleware.ts` MUST return the `supabaseResponse` object it creates — returning a
  fresh `NextResponse` instead drops the refreshed cookie and silently reintroduces
  the logout bug. This is the easiest thing to get wrong here.
- Don't re-add any localStorage session code; mixing the two storage modes causes
  intermittent logouts that are painful to debug.

## Recommended next step
Push to a Vercel preview deployment and test refresh-while-logged-in there, since
prod is the only place the bug reproduces. If it still logs out, check the preview's
env vars first (the most likely culprit) before touching the auth code.
```

The example is illustrative, not a script — adapt the depth and emphasis to the session you're actually handing off.
