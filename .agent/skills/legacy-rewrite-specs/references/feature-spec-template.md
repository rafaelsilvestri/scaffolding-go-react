# Feature Spec Template

Use this template only in Mode 2, after analysis approval.

```md
# Feature Spec: {feature_name}

## Status

- Spec status: Draft / Ready for implementation / Blocked
- Legacy analysis: {analysis_reference}
- Review decision log: {decision_log_reference}
- Target rules source: `{new_project_repo}/.agent/rules`

## Goal

{What this feature must accomplish in the new system.}

## Scope

In scope:
- {item}

Out of scope:
- {item}

## Source Traceability

| Requirement | Legacy evidence | Review decision | Target constraint |
|---|---|---|---|
| {requirement} | `{path}:{line}` | D-001 | `.agent/rules`, {design_system_source} |

## Actors and Permissions

| Actor/role | Capability | Rule | Evidence |
|---|---|---|---|
| {actor} | {capability} | {target_or_legacy_rule} | `{path}:{line}` |

## User Flows

### {Flow Name}

Trigger:
- {trigger}

Steps:
1. {step}
2. {step}

Expected result:
- {result}

Failure states:
- {failure_state}

## Business Rules

| Rule ID | Rule | Source | Review status |
|---|---|---|---|
| BR-001 | {rule} | `{path}:{line}` | Approved |

## Data and State

### Entities

| Entity | Purpose | Fields/relationships | Notes |
|---|---|---|---|
| {entity} | {purpose} | {fields} | {notes} |

### State Transitions

| From | Event/action | To | Side effects |
|---|---|---|---|
| {from} | {event} | {to} | {side_effects} |

## API and Integration Contracts

### {Endpoint or integration}

- Type: HTTP / RPC / GraphQL / event / job / webhook
- Method/topic: `{method_or_topic}`
- Auth: {auth}
- Request:

```json
{}
```

- Response:

```json
{}
```

- Errors:
  - {error}

## UI and Design System Mapping

Pages/screens:
- {screen}

Components:
- `{component}` for {usage}

States:
- Loading
- Empty
- Error
- Validation error
- Permission denied
- Success

Accessibility and responsive behavior:
- {requirement}

## Intentional Changes From Legacy

| Change | Legacy behavior | New behavior | Approved decision |
|---|---|---|---|
| {change} | {legacy} | {new} | C-001 |

## Acceptance Criteria

- {criterion}

## Parity Tests

| Test | Legacy behavior to preserve | Expected new behavior |
|---|---|---|
| {test} | {legacy_behavior} | {expected_behavior} |

## Open Questions

Only include questions that are explicitly accepted as non-blocking. Blocking questions belong in the review decision log.

- {question}
```

