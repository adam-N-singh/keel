# keel — Skill Invocation Research & Findings

**Period:** 2026-07-07 → 2026-07-14
**Status of this doc:** internal research notes. Untracked by git as of writing — commit/publish deliberately if desired.
**Purpose:** everything learned from packaging, deploying, and empirically testing keel's six skills, so future improvements are grounded in evidence rather than assumption.

---

## 1. Executive summary

Across four controlled runs (two greenfield one-shots, two cold-start continuations), a frontier model (Fable/Opus-class via Claude Code) invoked keel's skills **zero times** — despite an escalating ladder of visibility interventions, every one of which verifiably reached the model's context.

The core finding: **visibility was never the binding constraint; discretion was.** Frontier models have internalized the discipline keel encodes (spec thinking, orientation before editing, verification before completion claims). They perform the *function* inline to a comparable standard and skip the *ceremony*. The control arm (no skills) produced equivalent designs, equivalent test coverage, and equivalent verification rigor.

What survives this falsification:
1. **Hard enforcement** (blocking hooks) — the only mechanism that does not require the model's cooperation. Never yet exercised in a real run (see bug §6.1).
2. **Explicit invocation** (`/keel:<skill>`) as an on-demand artifact generator — always works, produces reviewable artifacts inline work does not leave.
3. **The weaker-model floor** — untested hypothesis that skills add value on Haiku-class or third-party agents that haven't internalized the discipline.
4. **The session-start index** — does not compel invocation, but demonstrably informs awareness (agents cited it accurately in every run).

---

## 2. How Claude Code decides which skills the model sees (documented mechanics)

Researched from official docs (code.claude.com/docs: skills, plugins-reference, hooks, settings), 2026-07-09:

- The skills listing in the system prompt has a **budget of 1% of the model's context window**. Skill *names* are always listed; *descriptions* are shortened, then dropped, to fit.
- Descriptions are dropped **starting with the least-frequently-invoked skills**. Frequently-used skills keep full text. ⚠️ This creates a **cold-start death spiral** for new plugins: zero invocation history → first to lose descriptions → never seen → never invoked → never earn visibility.
- Each skill's `description` + `when_to_use` frontmatter is hard-capped at **1,536 characters combined** in the listing.
- There is **no priority field** of any kind — not in SKILL.md frontmatter, not in plugin.json, not in marketplace.json. `keywords` in plugin.json is marketplace-search-only.
- **`skillOverrides`** in settings.json is the only user-side pin: `{"skill-name": "on"}` forces full name + description; also supports `name-only`, `user-invocable-only`, `off`.
- Install method (marketplace plugin vs `~/.claude/skills` vs project skills) makes **no documented difference** to description priority.
- Plugins can ship hooks via `hooks/hooks.json` (auto-discovered, no plugin.json declaration needed — verified against the Vercel plugin, which uses this exact layout). `SessionStart` hook stdout/additionalContext lands in model context every session, **outside** the skills budget. `UserPromptSubmit` stdout is injected per-prompt. `Stop` hooks can block completion with `{"decision": "block", "reason": "..."}` (must respect `stop_hook_active` to avoid loops).
- `disable-model-invocation: true` removes a skill from Claude's context entirely (explicit-only) — the opposite of auto-triggering.

Empirical addendum (observed, not documented):
- **claude.ai account-level plugins cannot be disabled via project `enabledPlugins`** — they load regardless, keeping the listing crowded even in a "keel-only" project. The SessionStart hook is what compensates.
- The `plugin details` command's "Hooks (0)" count does not reflect auto-discovered `hooks/hooks.json` (cosmetic; hooks fire regardless).

---

## 3. Experiment log

Test project: "Splitfair" — trip-expense web app (auth, trips, members, expenses, debt-simplification summary). Identical prompt in all arms. Arms configured via `.claude/settings.local.json` (all 16 user-scope plugins disabled locally; keel re-enabled in A arms only).

### Run 1 (splitfair-A, 2026-07-09) — pre-baseline
- keel installed, **no** hook, original descriptions.
- Transcript forensics: all six keel skills listed **name-only** — descriptions dropped by the budget. Trigger phrases appeared 0 times in 935KB transcript.
- Invocations: **0**. Root cause classified as visibility.

### Run 2A (splitfair2-A, 2026-07-14) — baseline (hook + reflowed descriptions)
- SessionStart index verified injected (1 hit). Some keel listing entries still name-only (account plugins crowd the budget), but index carried all six triggers.
- Invocations: **0**. Model's own post-hoc account: *"I skipped both and went straight to implementation since your request was already fairly concrete"*; for verification: *"did the equivalent work manually."*
- Reclassified root cause: **discretion, not visibility.**

### Run 2B (splitfair2-B, 2026-07-14) — control (no keel)
- Produced similar quality with self-driven testing (tsc, eslint, vitest, browser). User's assessment: models already do what the skills propose.

### Phase 2A continuation (2026-07-14) — hardened index + wave-2 nudge live
- Session-start index (invoke-by-default + mandatory skip justification): injected ✓
- UserPromptSubmit nudge naming exact skills: fired ✓
- Invocations: **0**. Justification rule ignored until asked. Model called it *"an oversight,"* not a judgment call.
- Orientation: 29 tool calls before first edit (self-directed context recovery). 104 total calls, ~21 min.

### Phase 2B continuation (2026-07-14) — control
- Invocations: 0 (of its available built-in skills). 17 calls before first edit, 120 total, ~13 min.

### Side-by-side (Phase 2)

| Metric | Arm A (keel, full soft stack) | Arm B (no skills) |
|---|---|---|
| Skill invocations | 0 | 0 |
| Duration | ~21 min | ~13 min |
| Total tool calls | 104 | 120 |
| Calls before first edit | 29 | 17 |
| Design chosen | `SettlementPayment` model, netted into balances | `Settlement` model — functionally identical design |
| Settlement test files | 2 | 2 |
| Verification before "done" | tsc, eslint, vitest, browser | tsc, eslint, vitest, browser |

Caveats: n=1 per arm; arms continued *different* codebases (A: service layer, no git; B: src/ layout, git); machine load uncontrolled. No signal favoring keel; if anything, A paid overhead without converting it.

---

## 4. What was built (all live on adam-N-singh/keel main unless noted)

| Commit | Change |
|---|---|
| `d0b0878` | Initial packaging: 6 skills, manifests, MIT, README |
| `9242023` | Marketplace-level description (silences validator warning) |
| `ea8ef1c` | Repoint to adam-N-singh profile |
| `8fb736b` | `.gitattributes`: LF pinned for .sh/.json/.md (CRLF breaks bash hooks on Windows clones) |
| `b4edbf0` | **Baseline**: SessionStart hook (`hooks/hooks.json` + `hooks/skills-index.md`, ~350 tok/session); descriptions reflowed trigger-first (always-on cost 1,616→1,284 tok); README skillOverrides + bootstrap guidance |
| `92127b0` (via `ea7582a`) | **Wave 2**: UserPromptSubmit keyword nudge; opt-in Stop gate (`.claude/keel-stop-gate` marker) |
| `efcdb04` | **Hardened index**: invoke-by-default, mandatory one-sentence skip justification, "inline equivalent is never valid," "greenfield ALWAYS qualifies" |

Design constraint honored throughout: skill *bodies* never modified — only frontmatter descriptions, packaging, hooks, docs.

---

## 5. Falsified vs. surviving hypotheses

**Falsified (on frontier models):**
- "Skills aren't invoked because descriptions get dropped" → fixed visibility; still 0 invocations.
- "Stronger instruction framing will compel invocation" → invoke-by-default + mandatory justification: ignored.
- "Nudging at the decision moment (prompt-submit) beats session-start" → nudge verifiably fired; 0 invocations.
- "Continuity tasks will showcase context-recovery" → the model did the skill's function inline on its strongest verbatim trigger.

**Surviving (untested or partially tested):**
- Hard gates change outcomes (Stop gate never exercised — see bug §6.1; PreToolUse edit-gate unbuilt).
- Skills add value on weaker models (Haiku-class) and non-Claude agents.
- Explicit invocation as artifact generator (structurally true; always works; value = reviewable artifacts for teams/audits).
- Handoff notes improve continuations (never tested — no arm-A session ever *wrote* one, so the continuation compared cold starts only).

---

## 6. Known bugs & issues

1. **Stop gate requires git** (`hooks/stop-gate.sh` checks `git rev-parse` + `git status --porcelain`). Run-2A's app never ran `git init`, so the gate can never fire there even with the marker. Fix: fall back to a non-git dirtiness heuristic, or drop the git requirement and use a session-scoped edit marker.
2. **Prompt nudge false-positives**: regex (`build|implement|create|add|...|migrate|...`) matches inside pasted quotes and reports (observed firing on a non-task message containing "prisma migrate dev"). Costs tokens on unrelated prompts; delivered zero invocations when correctly fired. Recommendation: remove.
3. **README overclaims**: currently says "skills fire automatically based on context" — contradicted by these experiments. Must be rewritten whatever direction keel takes.
4. **Account-level plugins undisableable per-project** (§2) — a "keel-only" test arm isn't fully isolatable; hooks are the only guaranteed channel.
5. Nested-session headless testing (`claude -p` spawned from a Claude session) fails auth (`CLAUDE_CODE_*` env vars defer to unavailable host auth). Tests must be run from a user terminal.

---

## 7. Recommendations

### Near-term product moves
1. **Reposition keel: enforcement + on-demand artifacts**, not auto-fired advice.
   - Headline: the Stop gate (post-fix) and, if built, a PreToolUse first-edit gate (block first Edit/Write until a spec artifact exists — opt-in, marker-based like the stop gate).
   - Skills documented as explicit commands (`/keel:verification-gate` → structured verified-vs-assumed report; `/keel:agent-handoff-summary` → handoff note before closing a session).
2. **Fix the stop gate git dependency** (§6.1) before promoting it.
3. **Remove the prompt nudge** (§6.2). Keep the SessionStart index — cheap, and it reliably produces *awareness* (useful for the justification norm and for users who ask "what applies here?").
4. **Rewrite the README** to make only claims the data supports (§6.3).

### Experiments worth running before final positioning
- **Haiku floor test**: same one-shot prompt, both arms, `--model haiku` (or model in settings). If Haiku's control arm skips verification or ships the settlement rounding bug, the "portable discipline for cheaper models" claim is real; if not, cut it.
- **Stop gate in anger**: after the git fix, a run with the marker set — measure whether the block reliably produces a verification-gate invocation.
- **Handoff value test**: force a handoff note at end of session 1 (explicit invocation), then compare a continuation against a no-note continuation. This is the still-unmeasured half of the continuity pair.
- **n>1**: any comparison that informs a README claim should be ≥3 runs per arm; single runs were adequate for falsifying invocation, not for quality deltas.

### Deeper strategic options (for contemplation)
- **Lean into artifacts as the product**: keel's unique output is the *paper trail* (spec, phase plan, verification report, verdict, handoff). Position for teams/reviewers/compliance rather than solo developers — "your agent's work, documented" — where inline-equivalent work genuinely doesn't substitute.
- **Target the agents that need it**: market/design for weaker models and non-Claude harnesses (skills are a portable open format). Frontier Claude may simply not be the customer.
- **Gate-first architecture**: reconceive each skill as (a) an enforcement hook that fires deterministically + (b) a skill body the hook directs the model through. Advisory-only skills demonstrably don't get used; gates + bodies might.
- **Accept the finding**: if further tests stay flat, shrink keel to what earns its keep (gate + handoff pair as explicit commands) — a narrow true claim beats a broad contradicted one.

---

## 8. Test infrastructure reference

- Arms live under `C:\Users\adams\projects\Personal\skilltests\`:
  - `splitfair-A` — run-1 artifact (pre-baseline). A rename attempt was blocked by a file lock; left in place.
  - `splitfair2-A` / `splitfair2-B` — run-2 + Phase-2 artifacts (A: keel-only local settings; B: all plugins off).
  - `splitfair3-A` — fresh, keel-only settings + `.claude/keel-stop-gate` marker, never used (was prepped for a wave-2 run; note the gate's git bug).
- Arm isolation: `.claude/settings.local.json` with `enabledPlugins` map (all `name@marketplace: false`, keel `true` in A arms).
- Post-run verification greps (transcripts in `~/.claude/projects/<dir-slug>/*.jsonl`):
  - Hook injected: `Select-String -Pattern "keel — agent discipline"`
  - Nudge fired: `Select-String -Pattern "keel: this looks like a coding task"`
  - Invocations: `Select-String -Pattern '"skill":\s*"keel:'`
- Deploy loop: edit → commit → push → `claude plugin marketplace update keel` → `claude plugin update keel@keel` → restart session (hook changes re-prompt for approval).
- Canonical skill sources: this repo. The claude.ai library originals were disabled 2026-07-07 (reversible toggles in Settings → Skills); a content-identical CRLF copy exists in `Familiar/.claude/skills/`.
