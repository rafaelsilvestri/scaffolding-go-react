# Design System Mapping Template

Use this template when the rewrite includes UI or UX changes.

```md
# Design System Mapping: {scope}

## Inputs

- Design system source: `{design_system}`
- Target project rules: `{new_project_repo}/.agent/rules`
- Legacy UI sources: `{paths}`

## Global UI Rules From Target Project

| Rule | Source | Application |
|---|---|---|
| {rule} | `{path}` | {application} |

## Component Mapping

| Legacy pattern | New design system component | Usage rule | Notes |
|---|---|---|---|
| {legacy_pattern} | `{component}` | {usage_rule} | {notes} |

## Page Patterns

| Page type | Layout | Required components | States |
|---|---|---|---|
| {page_type} | {layout} | {components} | Loading, empty, error, success |

## Forms

| Form pattern | Component(s) | Validation display | Submission behavior |
|---|---|---|---|
| {form} | {components} | {validation} | {behavior} |

## Tables and Lists

| Data pattern | Component(s) | Sorting/filtering/pagination | Empty/error states |
|---|---|---|---|
| {pattern} | {components} | {behavior} | {states} |

## Navigation

| Legacy navigation | New navigation | Permission behavior | Notes |
|---|---|---|---|
| {legacy} | {new} | {permission_behavior} | {notes} |

## Intentional UX Changes

| Change | Legacy behavior | New behavior | Reason | Approval |
|---|---|---|---|---|
| {change} | {legacy} | {new} | {reason} | {decision_id} |
```

