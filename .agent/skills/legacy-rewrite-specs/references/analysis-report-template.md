# Legacy Analysis Template

Use this template for Mode 1. Keep evidence and uncertainty visible.

```md
# Legacy Analysis: {scope}

## Inputs

- Legacy repository: `{legacy_repo}`
- New project repository: `{new_project_repo}`
- Target rules: `{new_project_repo}/.agent/rules`
- Design system: `{design_system}`
- Scope: `{scope}`
- Target premises:
  - {premise}

## Target Constraints Summary

Summarize constraints from `.agent/rules`, design system docs, and target premises that affect rewrite specs.

### Project Rules

| Rule | Source | Impact on rewrite |
|---|---|---|
| {rule} | `{path}` | {impact} |

### Design System Constraints

| Constraint | Source | Impact on UI specs |
|---|---|---|
| {constraint} | `{path}` | {impact} |

## Legacy System Map

### Modules and Features

| Module | Feature | Evidence | Notes |
|---|---|---|---|
| {module} | {feature} | `{path}:{line}` | {notes} |

### Routes and Entry Points

| Entry point | Type | Handler/source | Feature |
|---|---|---|---|
| `{route}` | HTTP/UI/job/event | `{path}:{line}` | {feature} |

### Data Model

| Entity/table/model | Fields of interest | Source | Notes |
|---|---|---|---|
| {entity} | {fields} | `{path}:{line}` | {notes} |

### Permissions and Access Control

| Actor/role | Capability | Evidence | Status |
|---|---|---|---|
| {role} | {capability} | `{path}:{line}` | Observed/Inferred/Unclear |

### Integrations and Side Effects

| Integration/side effect | Trigger | Evidence | Notes |
|---|---|---|---|
| {integration} | {trigger} | `{path}:{line}` | {notes} |

## Behavior Inventory

### {Feature or Flow}

Status: Observed/Inferred/Unclear/Conflicting/Missing evidence

Observed behavior:
- {behavior}

Business rules:
- {rule}

Validation and errors:
- {validation_or_error}

State changes and side effects:
- {state_change_or_side_effect}

Evidence:
- `{path}:{line}` - {what this proves}

Unclear or conflicting points:
- {unclear_point}

## Risks

| Risk | Impact | Evidence | Recommended decision |
|---|---|---|---|
| {risk} | High/Medium/Low | `{path}:{line}` | {decision_needed} |

## Review Required

The following items must be reviewed before final specs are generated:

- {decision_needed}
```

