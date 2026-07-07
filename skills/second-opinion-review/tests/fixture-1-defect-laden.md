# Fixture 1 — Defect-Laden ("catch" test)

**What this tests:** whether the skill *catches* serious, expensive problems and tags
them with the right severity. The input is a PR that is wrong in many ways at once,
including the most dangerous category — an irreversible, unauthenticated, injectable
mass-delete.

**One-line pass condition:** the skill flags the auth, injection, GET-method, and
irreversibility issues as **Blocking** and returns a **Stop** verdict.

## How to run

1. Start a fresh session and invoke the skill (`/second-opinion-review`, or just ask it
   to review the change — a fresh session matters so prior context doesn't leak in).
2. Paste everything between the `==== PASTE START / END ====` markers.
3. Grade the output against the answer key below.

```
==== PASTE START ====
Review this PR before I merge it.

PR: "Add account deletion + data export" (Next.js App Router + Supabase)
Description: "Lets users delete their account and all their data. Tested manually
on my machine, works. Ready to merge."

--- app/api/account/delete/route.ts (new) ---
import { createClient } from '@supabase/supabase-js'
import _ from 'lodash'

const admin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

class EntityDeleter {
  constructor(private table: string) {}
  async deleteFor(userId: string) {
    const { error } = await admin.rpc('exec', {
      sql: `DELETE FROM ${this.table} WHERE user_id = '${userId}'`,
    })
    if (error) throw error
  }
}

export async function GET(req: Request) {
  const userId = new URL(req.url).searchParams.get('userId')
  if (_.isEmpty(userId)) return new Response('missing userId', { status: 400 })

  for (const t of ['wikis', 'sources', 'api_keys', 'profiles']) {
    await new EntityDeleter(t).deleteFor(userId!)
  }
  return new Response('deleted', { status: 200 })
}

--- supabase/migrations/0042_drop_soft_delete.sql (new) ---
ALTER TABLE profiles DROP COLUMN deleted_at;

--- package.json ---
+ "lodash": "^4.17.21"

No test files changed.
==== PASTE END ====
```

---

## Expected findings — ANSWER KEY (do NOT paste this section into the skill)

Planted issues and the severity the skill should assign:

| # | Planted issue | Expected severity |
|---|---|---|
| 1 | No authn/authz — `userId` read from the query string (IDOR; anyone can delete anyone) | **Blocking** |
| 2 | SQL injection — `userId` string-interpolated into raw SQL run with the service-role key | **Blocking** |
| 3 | Destructive action exposed over **GET** (CSRF / link-prefetch / crawler can trigger it) | **Blocking** |
| 4 | Irreversible hard delete **and** the same PR drops `deleted_at`; promised export not implemented | **Blocking** |
| 5 | `rpc('exec', { sql })` bypasses RLS / the app's normal Supabase pattern | Should-fix |
| 6 | `EntityDeleter` class wraps a single method to replace a 4-line loop (overengineering) | Consider |
| 7 | `lodash` added solely for `_.isEmpty` on a string | Consider |

Should also appear:
- **Hidden assumptions** — an `exec` RPC exists and is safe to expose; FK delete-ordering
  is harmless (deleting `profiles` before its referencing rows may throw mid-loop, leaving
  a half-deleted account); table names are exactly those four; "works on my machine" says
  nothing about the destructive edge paths.
- **Verification gaps** — no automated tests on an irreversible op; the manual check covers
  only the happy path for one's own account, not the IDOR / injection / CSRF / FK / partial-
  failure paths.

**Expected verdict:** **Stop.**

### Failure signals (the skill regressed if you see these)
- Any of issues 1–4 missing, or rated below **Blocking** → under-catching the expensive stuff.
- Verdict softer than **Stop** → severity calibration is broken.
- A required output section missing or out of order → format drift.
