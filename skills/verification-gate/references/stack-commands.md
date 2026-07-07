# Extracting verification commands per ecosystem

Read this when the condensed table in SKILL.md is not enough — for example when a project uses custom script names, an aggregate command, or a less common stack. The goal is always the same: find the command the project *itself* would run to verify a change, not a generic guess.

## General rule

A documented or scripted command always beats a default. Many repos define a single aggregate gate (`make ci`, `npm run check`, `just verify`, `tox`, a CI job). Prefer it — it usually runs typecheck + lint + tests + build the way the maintainers intend. If you find one, run it (if safe) before falling back to individual tools.

CI files are the most reliable source of truth: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `azure-pipelines.yml`, `.circleci/config.yml`. They list the exact commands that must pass for the project to ship.

## Node / TypeScript

- Read `package.json` `"scripts"`. Common keys: `test`, `lint`, `typecheck`/`type-check`, `build`, `check`, `ci`, `validate`. Run via the right manager.
- Pick the manager from the lockfile: `package-lock.json` -> npm, `pnpm-lock.yaml` -> pnpm, `yarn.lock` -> yarn, `bun.lockb` -> bun. Using the wrong one can rewrite the lockfile.
- No `typecheck` script but `tsconfig.json` present -> `npx tsc --noEmit`.
- Monorepos (`turbo.json`, `nx.json`, workspaces): there may be a root-level `turbo run build test lint` or `nx affected`. Prefer the affected/changed scope over the whole tree.

## Python

- `pyproject.toml`: look for `[tool.pytest]`, `[tool.mypy]`, `[tool.ruff]`, `[tool.poetry.scripts]`, and a `[tool.hatch.envs.*.scripts]` block.
- `tox.ini` / `noxfile.py`: `tox` or `nox` runs the project's full matrix; a single env like `tox -e py311` is cheaper.
- Tests: `pytest` or `python -m pytest`. Scope it: `pytest path/to/affected`.
- Types: `mypy <pkg>` or `pyright`. Lint: `ruff check` (modern) or `flake8`/`pylint`.
- Respect the virtualenv. If there's a `poetry.lock`, prefer `poetry run <cmd>`; for `uv`, `uv run <cmd>`.

## Rust

- `cargo check` is the fast compile gate; `cargo clippy -- -D warnings` is the lint gate; `cargo test` runs tests; `cargo build --release` for release builds.
- Workspaces: add `--workspace` to cover all members.

## Go

- `go build ./...`, `go vet ./...`, `go test ./...`. Lint via `golangci-lint run` if `.golangci.yml` exists.
- A `Makefile` target (`make test`, `make lint`) is common and often the intended entry point.

## Java / Kotlin / JVM

- Maven (`pom.xml`): `mvn -q verify` runs compile + test + checks; `mvn test` for tests only.
- Gradle (`build.gradle[.kts]`): `./gradlew build` (includes tests), `./gradlew test`, `./gradlew check`. Use the wrapper (`./gradlew`), not a system `gradle`.

## .NET / C#

- `dotnet build` compiles (and surfaces type errors). `dotnet test` runs the test projects. `dotnet format --verify-no-changes` checks style without editing.
- Point at the solution or project if there are several: `dotnet test path/to/Project.Tests.csproj`.

## Ruby

- `Gemfile` + `bundle install` resolves deps. Tests: `bundle exec rspec` or `bundle exec rake test`. Lint: `bundle exec rubocop`.

## PHP

- `composer.json` `"scripts"` often defines `test`, `analyse`, `cs`. Run `composer <script>`. Static analysis: `phpstan analyse` / `psalm`. Tests: `phpunit` / `vendor/bin/phpunit`.

## Make / just / shell

- `make help` or reading the `Makefile` reveals targets; common ones: `test`, `lint`, `build`, `check`, `ci`, `fmt`. `just --list` for justfiles.
- Treat these as the project's preferred interface when present — they exist precisely so contributors don't have to remember the underlying commands.

## Databases and migrations (run with care)

- Validate without mutating real data: many tools have a check/dry-run (`alembic upgrade --sql`, `prisma migrate diff`, `npx drizzle-kit check`, `dotnet ef migrations script`). Generating the SQL without applying it is a safe verification.
- Apply migrations only against a local/test/throwaway database, never a shared or production one, and never one you can't confirm is disposable.
- If you cannot safely run the migration here, say so under "What was not checked" and state what the user should run.

## When nothing is found

If there are no scripts, no Makefile, no CI, and no docs, verification is limited to what the language gives you for free (compile/typecheck) plus a careful manual read of the diff. Report exactly that and mark the status Partially complete — the absence of checks is a finding, not a pass.
