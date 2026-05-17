# 10 — Architecture

## Monorepo topology

```
apps/
├── api/    # Go: HTTP backend, domain source of truth
└── web/    # React: client that consumes the REST API

docs/api/openapi.yaml    # Contract. Both sides conform to it.
```

> The OpenAPI contract is the **only allowed coupling** between `apps/api` and `apps/web`. Do not import anything from one app into the other.

## Backend (apps/api)

Layers, outside in:

```
cmd/server/         # Entry point. Wire deps, start server.
internal/
├── http/           # Handlers, middleware, routing. No business rules.
│   ├── handlers/
│   ├── middleware/
│   └── response/   # Result<T, E> envelope, status code helpers
├── domain/         # Pure entities + business rules (no I/O)
├── service/        # Use cases. Orchestrates domain + storage.
├── storage/        # Persistence (sqlc-generated + repos)
└── config/         # Env var loading + validation
```

**Rules**:

1. `domain/` does not import from `http/`, `storage/`, or `service/`
2. `service/` imports `domain/` and `storage/`. It does not import `http/`.
3. `http/` imports `service/`. It does not know SQL.
4. Dependencies flow **inward**. Never the reverse.
5. Every handler has an integration test (httptest) covering: happy path, validation, service error.

## Frontend (apps/web)

```
src/
├── api/            # HTTP client generated from OpenAPI + query hooks
├── components/     # Reusable components, no direct fetch
├── features/       # Folders by product feature (login, dashboard, etc.)
│   └── <feature>/
│       ├── components/
│       ├── hooks/
│       └── routes.tsx
├── lib/            # Pure utilities (formatters, validators)
└── App.tsx
```

**Rules**:

1. Components in `components/` do not fetch — they receive data via props
2. Data fetching only in hooks inside `features/<f>/hooks/` or `api/`
3. Server state: TanStack Query. Local state: `useState`/`useReducer`. No Redux.
4. Routing: `react-router` or `tanstack-router` — choice defined in ADR-0002

## Contract and type generation

- Source of truth: `docs/api/openapi.yaml`
- Backend generates handler stubs with `oapi-codegen` (optional)
- Frontend generates types and functions with `openapi-typescript` + `openapi-fetch`
- CI validates: spec → generated types → code compiles → tests pass

## Migrations

- Folder: `apps/api/migrations/`
- Forward-only. Never edit an applied migration — create a new one.
- Name: `YYYYMMDDHHMM_<description>.up.sql` and `.down.sql`
- `down.sql` exists for local emergencies. In production, we forward-fix.

## Observability

- Structured logs (`slog` in Go) with correlation by request ID
- Metrics via `/metrics` (Prometheus) — middleware in the router
- Traces via OpenTelemetry when enabled by env var

## Performance

- REST endpoints p95 < 200ms for read operations
- N+1 is a bug, not an optimization — catch it in code review
