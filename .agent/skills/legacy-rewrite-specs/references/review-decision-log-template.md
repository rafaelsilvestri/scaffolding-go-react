# Review Decision Log Template

Use this template to force the review gate between legacy analysis and final specs.

```md
# Review Decision Log: {scope}

## Review Status

- Status: Draft / In review / Approved / Approved with exceptions / Blocked
- Reviewer: {name_or_role}
- Date: {date}

## Decision Categories

Use one of these statuses:

- `Approve as-is`: preserve behavior exactly.
- `Approve inferred`: accept inferred behavior as a requirement.
- `Intentional change`: new system should differ from legacy.
- `Needs clarification`: do not include in final specs yet.
- `Out of scope`: exclude from this rewrite scope.
- `Legacy bug`: document but do not preserve unless explicitly requested.

## Decisions

| ID | Topic | Legacy finding | Proposed decision | Final decision | Notes |
|---|---|---|---|---|---|
| D-001 | {topic} | {finding} | {proposal} | {status} | {notes} |

## Ambiguities

| ID | Topic | What is unclear | Evidence | Required answer | Owner | Status |
|---|---|---|---|---|---|---|
| A-001 | {topic} | {unclear} | `{path}:{line}` | {question} | {owner} | Needs clarification |

## Intentional Changes

| ID | Legacy behavior | New behavior | Reason | Approved by |
|---|---|---|---|---|
| C-001 | {legacy_behavior} | {new_behavior} | {reason} | {reviewer} |

## Blockers Before Final Specs

- {blocker}
```

