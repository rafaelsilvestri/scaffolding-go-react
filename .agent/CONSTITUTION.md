# Project Constitution: scaffolding-go-react

> This file is read by the agent at the start of **every** conversation. Keep it short and dense.

## Mission

Example web application that demonstrates Spec-Driven Development with AI agents, using a Go + React stack separated by an OpenAPI contract.

## Irreversible decisions (do not revisit without an ADR)

- **Backend**: Go 1.22+ (modules, no `gopath`). `chi` router, SQL via `sqlc`. No magic ORM. See `specs/adrs/0001-stack-choice.md`.
- **Frontend**: React 18 + strict TypeScript (`strict: true`, `noUncheckedIndexedAccess: true`). Vite. Server state via TanStack Query. No global Redux.
- **Database**: PostgreSQL 16. Forward-only migrations via `golang-migrate`.
- **API**: REST with OpenAPI 3.1 in `docs/api/openapi.yaml`. Every surface change updates the contract **before** the code.
- **Errors**: `Result<T, E>` envelope (see `apps/api/internal/http/response/`). Never return a loose `{ error: "..." }`. See ADR-0003.
- **Auth**: OAuth2 + PKCE (not implemented in this example, but decided).

## Code style

- **Go**: `gofmt`, `go vet`, `golangci-lint` (config in `apps/api/.golangci.yml`). Small functions, errors as values, no `panic` outside `main`.
- **TS**: strict ESLint, no `any` (use `unknown` + narrowing). Functional components with hooks. No `useEffect` for data fetching — use TanStack Query.
- Test names describe **behavior**, not implementation.

## Essential commands

| Command | What it does |
|---|---|
| `make setup` | Installs api + web dependencies |
| `make dev` | Starts backend (`:8080`) and frontend (`:5173`) in parallel |
| `make test` | `go test ./...` + `pnpm -r test` |
| `make lint` | `golangci-lint run` + `pnpm -r lint` |
| `make typecheck` | `tsc --noEmit` in all JS packages |
| `make validate` | Validates code against OpenAPI |
| `make migrate-up` | Applies migrations to the local DB |

## Mandatory workflow

1. **Read the feature spec** before coding (in `specs/<id>-<slug>/spec.md`)
2. **Plan mode** before editing more than one file
3. **Update OpenAPI first** when changing the API surface
4. **Tests ship with the commit** (same PR) — there is no "tests next sprint"
5. **QA cycle** after implementation: the `qa-cycle` skill orchestrates `test-planner` → `test-runner` → `bug-reporter` → `bug-fixer`. Output in `specs/<id>-<slug>/qa/`. **Automatic trigger**: the PostToolUse hook detects when `specs/<id>/tasks.md` has all checkboxes checked and emits a nudge requiring the agent to invoke `qa-cycle` before any commit/push. To skip in rare cases (e.g., spike without tests, docs-only change), create `specs/<id>/qa/.skip-qa-cycle` with the textual justification.
6. **Subagent `spec-verifier`** runs before opening a PR

## Where to find things

- Feature specs: `specs/<id>-<slug>/`
- Feature QA artifacts: `specs/<id>-<slug>/qa/` (test-plan, test-results, bug-report, fix-log)
- ADRs: `specs/adrs/`
- Domain glossary: `docs/domain/glossary.md`
- Code standards: `.agent/rules/`
- Procedures: `.agent/skills/` (includes `qa-cycle` for the closed validation loop)
- Subagents: `.agent/agents/` — `reviewer`, `spec-verifier`, `security-auditor`, `test-planner`, `test-runner`, `bug-reporter`, `bug-fixer`

## Project skills

`.agent/skills/` is this project's default versioned skill source for Codex and Claude Code. Do not depend on global skills in `~/.codex/skills` or local symlinks to run project procedures.

When the user mentions a skill by name, or when the task clearly matches an existing skill, first read `.agent/skills/<skill-name>/SKILL.md` and follow the flow defined there. If the skill has `references/`, load only the files needed for the current task.

Available skills:

- `add-migration`: create forward-only migrations.
- `create-rest-endpoint`: create or change REST endpoints following OpenAPI.
- `create-react-component`: create React components in the project pattern.
- `qa-cycle`: run the feature's closed validation cycle.
- `legacy-rewrite-specs`: analyze a legacy repository and generate revised specs for a rewrite.

## What to avoid

- **Do not use `any` in TS** — prefer `unknown` + narrowing
- **Do not use `interface{}` in Go** except in tests or plumbing — prefer generics or concrete types
- **Do not invent libraries** — check `go.mod`/`package.json` before importing
- **Do not create files outside `apps/`, `specs/`, `docs/`, or `.agent/`** without explicit instruction
- **Do not run** `rm -rf` outside `dist/`, `build/`, `node_modules/`, or `/tmp`
- **Do not run** destructive migrations (`DROP TABLE`, `TRUNCATE`) outside `*_test` databases
- **Do not use `git push --force`** on `main` or `release/*`
- **Do not publish packages** (`npm publish`, `goreleaser release`) — releases are via GitHub Actions

## When to say "I don't know"

If the spec is ambiguous, **stop and ask**. Do not invent behavior. Do not invent field names, error codes, or API contracts — read them from OpenAPI.

## Active hooks in this repo (3 layers)

This repository applies defense in depth. You cannot ignore any layer:

1. **Claude Code hooks** — `.claude/settings.json` registers `.agent/hooks/pre-tool-use.sh` (blocks destructive commands before execution) and `.agent/hooks/post-tool-use.sh` (runs lint/format/vet on every edit). Blocks arrive as `exit 2`, and you see the reason in stderr — read it and adjust the approach.
2. **Git hooks (lefthook)** — `lefthook.yml` runs on pre-commit (staged lint), pre-push (tests), and commit-msg (Conventional Commits). Even if you get through the Claude Code hooks, the commit can still be blocked here.
3. **CI (GitHub Actions)** — `.github/workflows/ci.yml` repeats all checks against `main`. The last barrier before merge.

For bypass flags (rare, for specific cases), see `.agent/rules/99-forbidden.md` — they always require explicit human approval in chat.

## Context

- This repository follows the report `relatorio-boas-praticas-projeto-ai-spec-driven.md` (root)
- The constitution (this file) is the only source of universal rules. Specific details go in `.agent/rules/` or skills.
