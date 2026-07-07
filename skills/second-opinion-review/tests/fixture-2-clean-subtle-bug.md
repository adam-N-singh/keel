# Fixture 2 — Clean, One Subtle Bug ("don't-over-flag" test)

**What this tests:** the harder and more important guardrail — whether the skill
*avoids manufacturing problems* on sound work while still catching one genuine subtle
bug. A reviewer that nitpicks everything into a permanent "Revise" is as useless as one
that rubber-stamps everything. This is the fixture most likely to expose a bad edit to
the skill.

**One-line pass condition:** the skill returns **Proceed**, rates the non-unique-cursor
bug as **Should-fix** (not Blocking, not omitted), and invents no blocking issues.

## How to run

Same as fixture 1: fresh session, invoke the skill, paste the block, grade against the key.

```
==== PASTE START ====
Review this PR before I merge it.

PR: "Paginate GET /api/wikis list endpoint"
Description: "List was returning every wiki; added cursor pagination. Added a test,
ran the suite locally, green."

--- app/api/wikis/route.ts (modified) ---
export async function GET(req: Request) {
  const session = await getSession(req)
  if (!session) return json({ error: 'unauthorized' }, 401)

  const url = new URL(req.url)
  const limit = Math.min(Number(url.searchParams.get('limit') ?? 20), 100)
  const cursor = url.searchParams.get('cursor')

  let q = supabase
    .from('wikis')
    .select('id, title, updated_at')
    .eq('user_id', session.userId)
    .order('updated_at', { ascending: false })
    .limit(limit)

  if (cursor) q = q.lt('updated_at', cursor)

  const { data, error } = await q
  if (error) return json({ error: error.message }, 500)

  const nextCursor = data.length === limit ? data[data.length - 1].updated_at : null
  return json({ wikis: data, nextCursor })
}

--- app/api/wikis/route.test.ts (new) ---
Covers: only the caller's wikis are returned; limit is respected; nextCursor is set
when more pages exist and null on the last page; 401 when unauthenticated.

No new dependencies.
==== PASTE END ====
```

---

## Expected findings — ANSWER KEY (do NOT paste this section into the skill)

| # | Item | Expected handling |
|---|---|---|
| 1 | Cursor keys on `updated_at` alone — not unique; rows skipped or repeated at a page boundary when two rows share a timestamp. **This is the one real bug.** | **Should-fix** |
| 2 | `Number(limit)` yields `NaN` on non-numeric input (`?limit=abc`), passed to `.limit(NaN)` | Consider |

Should also appear in **What looks good** (proof the skill actually read it):
- Session is verified and the query is scoped to `session.userId` (no cross-user read).
- `limit` is clamped to 100 (closes the "ask for a million rows" abuse).
- Reuses the existing `supabase` client and `json` helper — no new pattern, no new deps.
- Tests cover the unauthorized path and both cursor states, not just the happy case.

**Simpler alternative** should say roughly "none worth making" — offset pagination would
read simpler but is worse. (If the skill pushes a simpler rewrite here, it's over-reaching.)

**Expected verdict:** **Proceed.**

### Failure signals (the skill regressed if you see these)
- Verdict of **Revise** or **Stop**, or the cursor bug rated **Blocking** → over-flagging /
  severity inflation. This is the main thing this fixture guards against.
- Cursor bug missing entirely → under-catching subtle correctness issues.
- "What looks good" empty, generic, or padded → the skill isn't grounding in the artifact.
