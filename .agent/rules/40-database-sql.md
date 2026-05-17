# 40 — Database, SQL, and sqlc

> Applies to PostgreSQL 16 access from the Go backend. Prefer boring, typed SQL through sqlc over dynamic query construction.

## Source of truth

- Schema changes live in `apps/api/migrations/`.
- Application queries live in `apps/api/db/queries/`.
- Generated Go code lives in `apps/api/internal/storage/queries/`.
- Repositories in `internal/storage/` wrap sqlc-generated code and translate storage concerns into service/domain-facing types.
- Do not edit sqlc-generated files manually. Change SQL, regenerate, then adapt callers.

## Query safety

- **Always use sqlc parameters.** Never build SQL with string concatenation, `fmt.Sprintf`, or user-controlled fragments.
- Dynamic sorting/filtering must use explicit allowlists mapped to fixed SQL branches. User input never becomes an identifier, operator, or raw clause.
- Avoid `SELECT *`. List columns explicitly so sqlc types and API behavior do not drift accidentally.
- Use `RETURNING` for writes that need generated values. Do not issue a second query unless there is a real reason.
- Use `pgx` typed values and sqlc null handling. Do not encode nullable DB state as ambiguous zero values.
- Treat `pgx.ErrNoRows`/no-row cases explicitly in storage and map them to domain/service errors. Do not leak driver errors to HTTP handlers.

## Performance

- Every query must have a predictable cardinality. Use `LIMIT` for list endpoints and keyset pagination for growing tables.
- Avoid offset pagination on large or user-facing collections unless the spec explicitly accepts the cost.
- N+1 queries are bugs. Prefer joins, `EXISTS`, batched lookups, or dedicated list queries.
- Add indexes with the migration that introduces the query path. Index foreign keys, frequent filters, and ordering keys used by production endpoints.
- Validate non-trivial queries with `EXPLAIN (ANALYZE, BUFFERS)` before merging when they touch large tables, joins, or new indexes.
- Do not rely on application-side filtering for rows that PostgreSQL can filter safely and clearly.
- Use transactions to reduce round trips when a use case performs multiple dependent writes.

## Transactions and concurrency

- Transaction boundaries belong in the service/use-case layer, not inside HTTP handlers.
- Pass `context.Context` through every database call. Do not use `context.Background()` inside storage code.
- Use `pgx.Tx`/sqlc `WithTx` for multi-step changes that must commit atomically.
- Keep transactions short: no network calls, slow computation, or user interaction while a transaction is open.
- Choose row locking intentionally (`FOR UPDATE`, `SKIP LOCKED`, advisory locks) and document the invariant being protected.
- Prefer database constraints for uniqueness and integrity, then handle constraint violations in Go.

## Migrations and schema design

- Migrations are forward-only. Never edit an applied migration; create a new one.
- Make production-safe migrations: add nullable columns first, backfill separately when needed, then enforce `NOT NULL`/constraints.
- Avoid table rewrites and long blocking locks on hot tables. For risky changes, split the migration and document the rollout.
- Constraints are part of the domain model: use `NOT NULL`, `UNIQUE`, `CHECK`, foreign keys, and sensible `ON DELETE` behavior.
- Timestamps use `timestamptz`. Do not use local-time `timestamp` for persisted events.
- Prefer `uuid` or stable business identifiers for public references. Never expose sequential internal IDs unless the API contract explicitly does.
- Destructive migrations (`DROP`, `TRUNCATE`, irreversible data deletion) require explicit human approval and must follow `.agent/rules/99-forbidden.md`.

## Security and privacy

- Store only the data required by the spec. Do not add PII columns speculatively.
- Do not log raw SQL parameters when they may contain secrets, tokens, credentials, or PII.
- Enforce authorization before querying sensitive rows, or encode ownership/tenant constraints directly in the query.
- Multi-tenant queries must include the tenant/account boundary in the SQL predicate. Filtering after retrieval is not acceptable.
- Prefer least-privilege DB roles per environment. Application code should not require migration-owner privileges at runtime.
- Use database constraints as a final integrity guard, but never treat them as a substitute for HTTP boundary validation.

## Go repository pattern

- Keep sqlc generated types inside the storage boundary. Services should depend on repository methods that express use cases, not raw query names.
- Repository methods should accept domain-oriented parameters and return domain/service-facing values.
- Wrap driver errors with context using `%w`; preserve enough detail for debugging without leaking sensitive values.
- Do not introduce an ORM or reflection-heavy query builder. The project decision is SQL via sqlc.
- Keep repository interfaces small and consumer-owned when tests need fakes.

## Testing

- Storage integration tests use a real PostgreSQL database whose name ends in `_test`.
- Test migrations and sqlc queries together for meaningful repository behavior; do not test generated sqlc boilerplate.
- Cover constraint failures, no-row behavior, pagination boundaries, and authorization/tenant predicates.
- Performance-sensitive queries should have regression tests for query count or repository call shape when feasible.
