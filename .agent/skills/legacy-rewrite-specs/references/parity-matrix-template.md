# Parity Matrix Template

Use this template in final spec mode to make feature completeness testable.

```md
# Parity Matrix: {scope}

## Summary

| Area | Legacy coverage | New spec coverage | Status |
|---|---:|---:|---|
| {area} | {count} | {count} | OK / Partial / Blocked |

## Feature Parity

| Feature | Legacy behavior | New spec reference | Status | Notes |
|---|---|---|---|---|
| {feature} | {behavior} | `{spec_path}#{section}` | OK / Partial / Intentional change / Blocked | {notes} |

## Rule Parity

| Rule ID | Legacy rule | Evidence | New spec reference | Status |
|---|---|---|---|---|
| BR-001 | {rule} | `{path}:{line}` | `{spec_path}` | OK / Partial / Missing / Changed |

## Permission Parity

| Actor | Legacy capability | New capability | Status | Decision |
|---|---|---|---|---|
| {actor} | {legacy_capability} | {new_capability} | OK / Changed / Missing | {decision_id} |

## Validation and Error Parity

| Case | Legacy behavior | New behavior | Status |
|---|---|---|---|
| {case} | {legacy_behavior} | {new_behavior} | OK / Missing / Changed |

## Integration and Side Effect Parity

| Trigger | Legacy side effect | New side effect | Status |
|---|---|---|---|
| {trigger} | {legacy_side_effect} | {new_side_effect} | OK / Missing / Changed |

## Required Tests

| Test | Type | Covers | Priority |
|---|---|---|---|
| {test_name} | unit/integration/e2e/contract | {behavior} | High/Medium/Low |
```

