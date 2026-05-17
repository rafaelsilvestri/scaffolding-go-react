---
name: legacy-rewrite-specs
description: Use when analyzing a legacy software repository to produce reviewed, structured rewrite specifications for a new system. This skill is for migrations, rewrites, redesigns, design system adoption, feature parity analysis, behavior extraction, and legacy-to-target architecture planning. It requires reading the new project's .agent/rules, the new design system, and user-provided premises before producing specs, and it enforces a human review gate between legacy analysis and final rewrite specs.
---

# Legacy Rewrite Specs

## Overview

Use this skill to turn a legacy repository into reviewed rewrite specifications for a new system. The legacy system is the behavioral source of truth, while the new project's `.agent/rules`, design system, and architectural premises are the target constraints.

Do not generate final rewrite specs from an unreviewed legacy analysis. First produce an analysis package, surface ambiguities and inferred behavior, then wait for explicit user approval or corrections before producing final specs.

## Required Inputs

Ask for any missing input that cannot be inferred from the workspace:

- `legacy_repo`: path to the existing system repository.
- `new_project_repo`: path to the target system repository.
- `design_system`: path to design system docs, package, Storybook, component library, or design tokens.
- `scope`: full system, module list, feature list, route list, or user journey list.
- `target_premises`: architectural, technical, product, migration, or business constraints.

The target project's rules must be read from:

```text
{new_project_repo}/.agent/rules
```

If `.agent/rules` does not exist, stop and ask whether to proceed with explicit inline rules, create the rules first, or use a different path. Do not silently ignore missing target rules.

## Operating Modes

### Mode 1: Analyze Legacy

Use this mode when the user wants to analyze the legacy system, prepare for a rewrite, discover behavior, or create the first review package.

Steps:

1. Read `{new_project_repo}/.agent/rules` and summarize the target constraints that affect specs.
2. Inspect the design system only enough to identify available components, layout patterns, tokens, interaction patterns, and constraints.
3. Inspect the legacy repository for routes, screens, modules, services, entities, permissions, integrations, jobs, tests, schemas, and configuration.
4. Produce an analysis package using `references/analysis-report-template.md`.
5. Produce a decision and ambiguity log using `references/review-decision-log-template.md`.
6. Mark every material behavior with one of:
   - `Observed`
   - `Inferred`
   - `Unclear`
   - `Conflicting`
   - `Missing evidence`
7. End with a review request. Ask the user to approve, correct, reject, or classify ambiguous items.

Do not produce final specs in this mode unless the user explicitly says the analysis is approved.

### Mode 2: Generate Rewrite Specs

Use this mode only after the user approves the analysis or provides corrected decisions.

Steps:

1. Re-read or reference the approved analysis and review decisions.
2. Reconcile approved behavior with `.agent/rules`, target premises, and design system constraints.
3. Generate feature specs using `references/feature-spec-template.md`.
4. Generate design system mapping using `references/design-system-mapping-template.md` when UI behavior is in scope.
5. Generate a parity matrix using `references/parity-matrix-template.md`.
6. Mark intentional changes explicitly. Never hide behavior changes inside implementation details.
7. Include source traceability for every important rule, permission, validation, API behavior, or workflow.

Final specs may include only:

- Approved observed behavior.
- Approved inferred behavior.
- Approved intentional changes.
- Explicitly accepted unresolved risks.

## Core Rules

- Treat the legacy repository as the behavioral source of truth, not the architectural source of truth.
- Treat `{new_project_repo}/.agent/rules` as mandatory target constraints.
- Preserve business behavior unless the user marks a difference as an intentional change.
- Do not copy accidental legacy architecture, naming, duplication, layout, or coupling unless it is required for compatibility.
- Do not turn inference into a final requirement without review.
- Separate "what the system does" from "how the old code implemented it".
- Prefer structured APIs, schemas, route definitions, tests, migrations, and typed models as evidence over visual guesses.
- When evidence conflicts, document the conflict and require a decision.
- Specs must be implementation-ready but not overfit to the legacy code structure.

## Evidence Standards

Use these source types when available:

- Routes, controllers, API handlers, RPC handlers, GraphQL resolvers.
- Domain services, use cases, jobs, event handlers, workflows.
- Database schemas, migrations, ORM models, seed data.
- Frontend routes, pages, forms, tables, navigation, guards.
- Tests, fixtures, snapshots, QA scripts, E2E flows.
- Permission checks, feature flags, tenant logic, audit logs.
- Integration clients, webhooks, queues, scheduled tasks.
- Runtime configuration and environment variable usage.

For each important behavior, record source references with file paths and line numbers when practical.

## Recommended Output Layout

For analysis mode:

```text
rewrite-analysis/
  legacy-analysis.md
  review-decision-log.md
  feature-map.md
  parity-risk-register.md
```

For final spec mode:

```text
specs/
  architecture/
    target-system-overview.md
    migration-strategy.md
  features/
    {feature-name}.md
  ui/
    design-system-mapping.md
  testing/
    parity-matrix.md
```

Adjust paths to the user's repository conventions when they provide them.

## Reference Templates

Load only the templates needed for the current mode:

- Analysis package: `references/analysis-report-template.md`
- Review gate: `references/review-decision-log-template.md`
- Feature specs: `references/feature-spec-template.md`
- UI/design system mapping: `references/design-system-mapping-template.md`
- Parity verification: `references/parity-matrix-template.md`

