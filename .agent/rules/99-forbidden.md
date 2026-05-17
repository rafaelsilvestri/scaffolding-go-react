# 99 — Forbidden Actions

> Canonical list of what the agent **never** does in this repo. The `pre-tool-use.sh` hook enforces critical items.

## Commands never to run

- `rm -rf` on any path outside `dist/`, `build/`, `node_modules/`, `.next/`, `coverage/`, `/tmp/`
- `DROP TABLE`, `TRUNCATE`, `DROP DATABASE` in any database that does not end in `_test`
- `git push --force` or `git push -f` on `main`, `develop`, `release/*`
- `git reset --hard` on a branch that is not the agent's branch (`agent/*`)
- `npm publish`, `pnpm publish`, `goreleaser release` — releases are **only** via GitHub Actions
- `chmod 777` on any file
- `curl ... | sh` or `wget ... | bash` — install dependencies via `package.json`/`go.mod`
- `sudo` in any local context

## Patterns never to introduce in code

- `eval()` in JS/TS, `os/exec` with user input in Go
- String concatenation in SQL — always parameterize via sqlc
- `dangerouslySetInnerHTML` without explicit sanitization (DOMPurify)
- Direct `process.env.X` in application code — route through `internal/config/` or validated `import.meta.env`
- `any` in TypeScript
- `interface{}` or `any` in Go outside genuine plumbing
- `panic()` in Go outside `main` or unrecoverable initialization
- Hardcoded production URLs, secrets, tokens
- Versioned `*.local.*` files (these must go to `.gitignore`)

## Always confirm with the human before

- Modifying `infrastructure/`, `terraform/`, or any folder with cloud config
- Running migrations in any environment other than local
- Adding a new dependency to `go.mod` or `package.json` — explain **why** in the PR
- Changes that alter `docs/api/openapi.yaml` by removing fields (breaking change)
- Renaming or deleting files in `apps/api/internal/domain/` (business rules)
- Changes to `.agent/CONSTITUTION.md` or any ADR
- Git operations that rewrite history (`rebase -i`, `filter-branch`, `commit --amend` on an already pushed commit)
- Changes in `.github/workflows/` that remove validation steps
- Accessing external services not declared in `.mcp.json`

## Escalation path

If a rule above conflicts with a real need:

1. Stop. Explain the conflict to the human in prose.
2. Propose alternatives.
3. Wait for an explicit decision in chat.
4. If approved, record it in an ADR before executing.

> The rule is: when in doubt, **do not execute**. Ask.
