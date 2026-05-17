# 00 — Code Style

> Style rules that apply to all code in this repo. Read in every session.

## Universal principles

- **Clear names > long comments**. If you need a comment to explain the name, rename it.
- **Small functions**. Ideally < 30 lines. If it grows beyond that, there is usually an implicit concept worth extracting.
- **Errors as data, not control flow**. In Go, return `error`. In TS, return `Result<T, E>` or discriminated unions; throw exceptions only for programmer bugs (violated invariants).
- **Immutability by default**. Use `const` in TS whenever possible. In Go, avoid pointers that suggest mutation when not needed.
- **No "TODO without owner"**. Every `TODO` in code has a person's name and an issue link.

## Go

- `gofmt` and `goimports` are mandatory — they run in pre-commit
- `golangci-lint` with config in `apps/api/.golangci.yml`
- Package = one clear responsibility. No `utils/`, `helpers/`, `common/`
- Use `internal/` for everything that should not be imported by other modules
- Errors: use `fmt.Errorf("context: %w", err)` to preserve the chain. Do not use `errors.New` when there is context to add
- Logs: structured `log/slog`. No `fmt.Println` in production code
- Do not use `interface{}` (or `any`) except for genuine plumbing cases
- Use generics when they reduce duplication **and** clarify the signature. If a comment is required to understand it, do not use it
- Tests: `_test.go` in the same folder. Use `testify/require` or pure `testing` — choose one per package

## TypeScript

- `"strict": true` in `tsconfig.json` — non-negotiable
- `"noUncheckedIndexedAccess": true` — forces narrowing after `arr[i]`
- **No `any`**. Use `unknown` and narrow. If the library has no types, write the `.d.ts` in the project.
- Use `interface` for data shapes, `type` for unions and composition
- Functional components with hooks. No class components
- Props use a named `interface` (`UserCardProps`), not inline
- Avoid `useEffect` for data fetching — use TanStack Query
- The file name matches the default (or main) export: `UserCard.tsx` exports `UserCard`

## Imports

- Order: stdlib → third-party → workspace → relative
- Absolute imports via `@/` alias in the frontend (configured in `vite.config.ts`)
- In the backend, always use the full module path (`github.com/example/scaffolding/apps/api/...`)

## Comments

- **Document "why", not "what"**. The code already shows what it does.
- Public functions always have a doc comment (Go: starting with the function name; TS: JSDoc)
- `// TODO(rafael, #123): ...` — always with owner and issue
