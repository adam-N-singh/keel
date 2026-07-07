# second-opinion-review — regression tests

Two hand-built fixtures for sanity-checking the skill after you edit it. They exist so a
change to `SKILL.md` that quietly breaks the skill's judgment gets caught before you rely
on it.

## Why two fixtures (the design)

A skeptical-reviewer skill has two opposite failure modes, and you need a test for each:

- **Fixture 1 (defect-laden)** checks the obvious direction: *does it catch real, expensive
  problems?* Easy to pass.
- **Fixture 2 (clean, one subtle bug)** checks the direction that's easy to get wrong: *does
  it refrain from manufacturing problems on good work, while still finding the one genuine
  subtle bug?* A reviewer that always finds something "Blocking" trains you to ignore it, so
  this is the more valuable guardrail. Most bad edits to the skill will show up here first —
  as an inflated verdict on Fixture 2.

## How to run (manual — this is a judgment skill)

There's no automated grader for a subjective review skill, so you run it by hand:

1. Open a **fresh** Claude Code session (so earlier context doesn't leak in and pre-bias it).
2. Invoke the skill — `/second-opinion-review`, or just paste the input and ask for a review.
3. Open a fixture file, copy **only** the block between `==== PASTE START ====` and
   `==== PASTE END ====`, and send it. Do **not** paste the answer-key section — that's the
   grading rubric, not input.
4. Compare the output to that fixture's answer key and fill in the scorecard below.

Run both fixtures after any edit to `SKILL.md`. Two minutes, and it catches calibration drift.

## Scorecard (copy this per run)

```
Date / skill version: __________

FIXTURE 1 (defect-laden) — expected verdict: STOP
[ ] Issues 1–4 all caught and tagged Blocking (auth, injection, GET-delete, irreversibility)
[ ] Lower-severity items (exec/RLS, class, lodash) present and NOT inflated to Blocking
[ ] Hidden assumptions + verification gaps sections populated
[ ] All 8 output sections present, in order
[ ] Verdict = Stop
Result: PASS / FAIL    Notes: __________

FIXTURE 2 (clean, one subtle bug) — expected verdict: PROCEED
[ ] Non-unique-cursor bug caught and rated Should-fix (not Blocking, not omitted)
[ ] No invented blocking issues
[ ] "What looks good" is specific and real (auth scoping, limit clamp, test coverage)
[ ] Verdict = Proceed
Result: PASS / FAIL    Notes: __________
```

A regression usually looks like: Fixture 2 coming back **Revise/Stop**, or the cursor bug
rated **Blocking** — that means a recent edit pushed the skill toward over-flagging. Fixture 1
failing (a Blocking issue missed or downgraded) means it's under-catching.

## Honest caveat

These fixtures were authored alongside the skill, so passing them is a *sanity check*, not an
independent benchmark — the planted issues are known in advance. The real test is running the
skill on genuine diffs and plans you didn't design, where neither you nor the skill knows the
answer ahead of time. Treat these as a fast regression tripwire, not proof of quality. When you
hit a real review where the skill's call felt off (too harsh or too soft), consider distilling
that case into a third fixture here.
