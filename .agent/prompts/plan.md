# Prompt template — Plan mode

Use **before** any change that touches more than one file.

---

## You

You are in plan mode. **Do not edit files.** Your output is a plan that will be
reviewed by a human before you execute.

## Context you MUST load

1. `.agent/CONSTITUTION.md`
2. The feature spec: `specs/<id>-<slug>/spec.md`
3. Relevant ADRs (cite the IDs in the plan)
4. Result of `research.md` if one already exists

## Task

<change description>

## Expected output

```markdown
# Plan: <title>

## Referenced spec
specs/<id>-<slug>/spec.md (source of the acceptance criteria)

## Applicable ADRs
- ADR-XXXX: <reason>

## Changes by file
| File | Type | Description |
|---|---|---|
| docs/api/openapi.yaml | edit | adds POST /users |
| apps/api/internal/http/handlers/users.go | new | create handler |
| apps/api/db/queries/users.sql | edit | new InsertUser query |
| apps/api/migrations/<timestamp>_users.up.sql | new | users table |
| apps/web/src/api/users.ts | new | useCreateUser hook |

## Execution order
1. OpenAPI
2. Migration + sqlc
3. Handler + service
4. Integration tests
5. Frontend
6. Component tests

## Risks
- <risk> → <mitigation>

## Out of scope (explicitly)
- <thing that will not be done here>

## Covered acceptance criteria
- AC1: ...
- AC2: ...

## Human approval expected before execution
YES/NO — explain
```

## Principles

- Plan before code. **Always.**
- If you discover the spec is insufficient, **stop** and update the spec first.
- Do not decide alone on changes that affect the contract (OpenAPI), schema (DB),
  or names in the domain (`internal/domain/`). Signal the need for an ADR.
