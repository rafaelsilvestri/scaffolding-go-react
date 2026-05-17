---
name: add-migration
description: Use when the user asks to create a new database migration
  (PostgreSQL) in the Go backend. Covers naming, creating up/down pairs,
  sqlc query generation, updating code generation, and testing against the
  local database.
tools: [view, create_file, str_replace, bash_tool]
---

# Add a migration in this project

## Principles

- **Forward-only.** In production, we never roll back. `down.sql` exists for local emergencies.
- **Never edit an applied migration.** If it is wrong, create a new one that fixes it.
- **Destructive migrations require human approval.** The `pre-tool-use.sh` hook blocks `DROP TABLE`/`TRUNCATE` without an explicit flag.

## Preconditions

- You know **why** this migration exists (link to spec or ADR)
- The local DB is running (`make db-up`)
- You are not editing a migration that is already in `main`

## Step by step

### 1. Create the up/down pair

```bash
make migrate-create NAME=add_users_email_index
```

This creates:

```
apps/api/migrations/
  20260509143012_add_users_email_index.up.sql
  20260509143012_add_users_email_index.down.sql
```

### 2. Write the SQL

A safe example:

```sql
-- 20260509143012_add_users_email_index.up.sql
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS users_email_unique_idx
  ON users (lower(email));
```

```sql
-- 20260509143012_add_users_email_index.down.sql
DROP INDEX IF EXISTS users_email_unique_idx;
```

**Rules**:

- `IF NOT EXISTS` / `IF EXISTS` when safe — makes re-execution idempotent
- `CREATE INDEX CONCURRENTLY` on large tables to avoid locking
- Defaults for new columns that do not allow null
- If renaming a column: do it in two migrations (add new → backfill → remove old) to avoid breaking rolling deploys
- **Never** `DROP COLUMN` without first confirming no code uses it — ask for human approval

### 3. Apply locally

```bash
make migrate-up
```

### 4. Update sqlc queries (if applicable)

Edit `apps/api/db/queries/<resource>.sql`:

```sql
-- name: GetUserByEmail :one
SELECT * FROM users WHERE lower(email) = lower($1);
```

Regenerate:

```bash
make sqlc
```

This updates `apps/api/internal/storage/queries.sql.go`.

### 5. Update the repository layer

In `apps/api/internal/storage/<resource>.go`, expose the new method if it is used by the service.

### 6. Tests

- Add an integration test that covers the new path
- Tests run against a `*_test` DB that applies all migrations during setup

## Destructive migrations (mandatory approval)

Before `DROP COLUMN`, `DROP TABLE`, `TRUNCATE`, or `ALTER COLUMN ... TYPE` that loses precision:

1. Stop and explain to the human:
   - What will be removed
   - Who uses it today (search in `internal/`, sqlc queries, frontend)
   - Deployment plan (zero-downtime?)
2. Wait for "ok, proceed"
3. Set the env var `AGENT_DESTRUCTIVE_MIGRATION=1` before creating the file
4. After merging, open a follow-up issue to validate in staging

## Final verification

```bash
make migrate-down    # checks that down works locally
make migrate-up
make test-integration
```

## Anti-patterns

- ❌ Editing a migration that is already in `main`
- ❌ Migration that does both schema and data backfill in one giant transaction
- ❌ `DROP TABLE` without an agreed maintenance window
- ❌ Type changes (`varchar(50) → varchar(40)`) without checking existing data
