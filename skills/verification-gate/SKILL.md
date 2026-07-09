---
name: verification-gate
description: ALWAYS run before saying a coding task is "complete", "done", "working", or "fixed" — never claim completion without it. Triggers whenever Claude has edited code, generated or modified files, fixed a bug, refactored, changed dependencies, altered database code or migrations, changed API behavior, or touched frontend behavior. It makes Claude inspect what changed, find and run the project's real verification commands (tests, lint, typecheck, build, run checks), separate verified facts from assumptions, and report exactly what was and was not checked, so completion claims rest on evidence instead of hope.
---

# Verification Gate

## Why this exists

Claude tends to announce a coding task is done based on what the code *should* do, before confirming it actually does. A false "complete" is expensive: the user trusts it, moves on, and finds the breakage later, often somewhere harder to trace back. This skill is a gate that sits between "I changed the code" and "it's done." Before any completion claim, you find the project's own checks, run the safe ones, and report the evidence. Saying "I verified X by running Y and it passed" is worth far more than "this should work."

## The core rule

Never describe a task as complete, done, fixed, or working unless verification supports that claim. If verification was skipped, partial, or failed, say so plainly and set the status to match. When unsure between two statuses, pick the more conservative one.

## When to run

Run this before reporting completion of any change that touches behavior or shippable artifacts: edited code, generated or modified files, a bug fix, a refactor, a dependency change, database code or migrations, API behavior, or frontend behavior. If you are about to type "done", "fixed", "working", "complete", or "that should do it", stop and run the gate first.

## Workflow

**1. Inspect what changed.**
Run `git status` and `git diff` (and `git diff --staged`) to see exactly which files changed and how. If it is not a git repo, or the edits are only in this session, enumerate the files you touched and what you did to each (logic, config, deps, schema, API, UI). You cannot verify a change you cannot name.

**2. Identify the stack.**
Look for signal files: `package.json` + lockfile (`package-lock.json`/`pnpm-lock.yaml`/`yarn.lock`/`bun.lockb`), `tsconfig.json`, `pyproject.toml`/`setup.py`/`requirements.txt`, `Cargo.toml`, `go.mod`, `pom.xml`/`build.gradle`, `*.csproj`/`*.sln`, `Gemfile`, `composer.json`, `Makefile`/`justfile`. A repo can mix several.

**3. Find the verification commands.**
Project-specific instructions beat generic defaults, so check in this order:
- `CLAUDE.md`, `AGENTS.md`, `README`, `CONTRIBUTING`, `docs/` for documented commands.
- The config files themselves: `package.json` `"scripts"`, `Makefile`/`justfile` targets, `pyproject.toml` (`[tool.*]`, tox), CI files (`.github/workflows/*`, `.gitlab-ci.yml`) which often list the exact commands the project gates on.
- The condensed catalog below as a fallback. See `references/stack-commands.md` for how to extract the real command names per ecosystem.

**4. Decide what is safe to run.**
- Safe to run now: tests, linters, typecheckers, builds/compiles, `format --check`, `--help`/`--version`, dry runs, and a short app-run smoke check under a timeout.
- Do NOT run autonomously: anything that mutates shared or production state, real migrations against a real database, deploys, destructive file operations, commands needing secrets or credentials you do not have, calls with side effects on external services, or watchers with no timeout. For DB changes, prefer a dry-run or a local/test database only.
- When unsure, do not run it. List it under "What was not checked" with the reason.

**5. Run and capture.**
Run the safe commands. Record the *exact* command and the *real* result, including key error lines on failure. Do not paraphrase success into existence; show what you actually saw. If the project declares a tool that is not installed in this environment (for example pytest in `pyproject.toml` but not on the path), run the closest valid equivalent (for example `python -m unittest`) and record the substitution under "What was not checked" — a passing equivalent is real evidence, but it is not the exact gate the project defined, and collection or config differences could change the result.

**6. Map each change to a check.**
Confirm the right kind of check ran for each kind of change:
- Dependencies changed -> install resolves + build/test pass.
- Database/schema/migration -> migration validates (dry-run or test DB) + affected tests.
- API behavior -> contract/integration tests, or at minimum typecheck plus the tests covering the touched endpoints.
- Frontend behavior -> build + typecheck + lint, plus component/e2e tests if they exist, or a clearly described manual check.
If the relevant check does not exist, that gap is itself a finding.

**7. Separate fact from assumption.**
Verified means a command ran and you saw the result. Everything else (reasoning, "should work", "the logic looks right") is an assumption and must be labeled as one. Do not let assumptions dress up as facts.

**8. Decide the status and write the report** using the exact format below.

## Stack -> likely commands (condensed fallback)

| Stack (signal) | Typecheck | Lint | Test | Build / run |
|---|---|---|---|---|
| Node/TS (`package.json`) | `tsc --noEmit` or `npm run typecheck` | `eslint .` / `npm run lint` | `npm test` | `npm run build` |
| Python (`pyproject.toml`) | `mypy .` / `pyright` | `ruff check` / `flake8` | `pytest` | `python -m build`; run `python -m <pkg>` |
| Rust (`Cargo.toml`) | `cargo check` | `cargo clippy` | `cargo test` | `cargo build` |
| Go (`go.mod`) | `go vet ./...` | `golangci-lint run` | `go test ./...` | `go build ./...` |
| Java (`pom.xml`/Gradle) | (compile) | (plugin) | `mvn test` / `./gradlew test` | `mvn -q verify` / `./gradlew build` |
| .NET (`*.csproj`/`*.sln`) | (build) | `dotnet format --verify-no-changes` | `dotnet test` | `dotnet build` |
| Ruby (`Gemfile`) | — | `rubocop` | `bundle exec rspec` / `rake test` | — |
| PHP (`composer.json`) | `phpstan analyse` | (script) | `phpunit` / `composer test` | — |
| Make/just | — | `make lint` | `make test` | `make build` / `make check` |

Use the package manager the lockfile points to (npm/pnpm/yarn/bun). Prefer a documented `make ci`, `npm run check`, or similar aggregate command when one exists.

## Output format

ALWAYS produce this report before any completion claim. Keep it tight; evidence over prose.

```
## Verification Report

**Changed files**
- path/to/file — what changed, in one line

**Commands run**
- `exact command` → pass / fail (exit code or short result)
  (or: none — and why)

**Results**
- concise outcome per command, with the key evidence (error lines on failure)

**What passed**
- ...

**What failed**
- ... (include the actual error, briefly)

**What was not checked**
- ... and why (no e2e suite, requires prod DB, no credentials, out of scope, etc.)

**Remaining risks**
- ...

**Final status:** Complete / Partially complete / Not complete
```

## Deciding the final status

- **Complete** — every relevant safe check ran and passed; nothing material is left unverified, or the only unverified items are genuinely out of scope and stated as such.
- **Partially complete** — some checks passed but others failed, could not run, or do not exist; or the change cannot be fully verified in this environment.
- **Not complete** — a relevant check failed in a way tied to the change, or no meaningful verification was possible for a change that needs it.

If "Commands run" is `none` for a behavioral change, the status cannot be Complete. If no checks exist at all, say so honestly ("no automated checks found; relied on typecheck/build and a manual diff review") and mark it Partially complete rather than claiming more than you confirmed.

## Example

A user asks for a bug fix in a TS/Node service. After editing:

```
## Verification Report

**Changed files**
- src/auth/token.ts — fixed expiry comparison using seconds instead of ms

**Commands run**
- `npx tsc --noEmit` → pass
- `npm run lint` → pass
- `npm test -- src/auth` → fail (1 of 14)

**Results**
- Typecheck and lint clean.
- token.test.ts "rejects expired token" failed: expected 401, got 200.

**What passed**
- Compilation, lint, and 13 of 14 auth tests.

**What failed**
- The test covering the exact bug — the fix does not yet handle the equal-to-expiry boundary.

**What was not checked**
- Full suite (ran only src/auth); integration tests (require a running Redis I don't have here).

**Remaining risks**
- Boundary case at exact expiry; other modules importing this helper not yet run.

**Final status:** Not complete
```

The honest "Not complete" here is the whole point: the change compiled and looked right, but the test that matters caught it. Reporting that beats a confident "fixed."
