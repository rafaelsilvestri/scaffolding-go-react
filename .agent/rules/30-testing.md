# 30 — Testing

> Tests ship with the commit. No exceptions. PR without tests = PR rejected by CI.

## Pyramid

| Level | What it tests | Where | Amount |
|---|---|---|---|
| Unit | pure domain functions | adjacent `*_test.go`, adjacent `*.test.ts` | 70% |
| Integration | handler + real db or httpmock | `internal/http/handlers/*_test.go`, `apps/web/src/**/*.integration.test.ts` | 25% |
| E2E | critical flow (login, checkout) | `e2e/` (Playwright) | 5% |

## Backend (Go)

### Conventions

- Same folder as the code (`pkg/foo/bar.go` + `pkg/foo/bar_test.go`)
- Test name describes **behavior**:
  - ✅ `TestCreateUser_RejectsDuplicateEmail`
  - ❌ `TestCreateUser1`
- Use `t.Run("subcase")` for variations. Table tests when there are many.
- `httptest` for handlers; real database (with `_test` suffix) for repos.

### Mocks

- Small interfaces + hand-written fake implementation > generated mocks
- If an interface has more than 5 methods, it is too large to mock confidently

### Determinism

- No direct `time.Now()` — inject a `Clock` interface
- No direct random — inject an `IDGen` interface
- Test database cleans before each test (`TRUNCATE` in a rolled-back transaction)

## Frontend (React)

### Stack

- **Vitest** for unit + component
- **React Testing Library** — test user behavior, not implementation
- **MSW** (Mock Service Worker) to mock the REST API
- **Playwright** for E2E

### Principles

- ✅ `screen.getByRole('button', { name: /send/i })`
- ❌ `screen.getByTestId('submit-button')` (last resort)
- Do not test internal hook details. Test what the user sees.
- Use `userEvent` (not `fireEvent`) — simulates real interaction

## Coverage

- Do not treat coverage as a quality metric — treat it as a sanity check
- Minimum threshold: 70% in `domain/` and `service/` (Go), 60% global in the frontend
- Error paths **must** be tested — bugs that leak to production are almost always untested unhappy paths

## Spec ↔ Test

- Every item in `## Acceptance Criteria` of the spec becomes **at least** one test
- Convention: the test name cites the criterion ID (`TestUserSignup_AC1_ValidatesEmail`)

## When NOT to test

- Generated boilerplate (sqlc, OpenAPI types) — trust the generator
- Trivial wiring in `cmd/server/main.go`
- Mocks are code too — do not test mocks

## Performance

- Local test suite < 60s. If it exceeds that, split by parallelizing or moving to integration
- `go test -race ./...` always in CI
