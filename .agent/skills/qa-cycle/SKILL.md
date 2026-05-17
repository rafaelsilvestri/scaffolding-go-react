---
name: qa-cycle
description: Use when the user asks to validate a feature, "run QA", "close
  the cycle", "test and fix", or after implementing a new feature.
  Orchestrates the 4 subagents in the cycle (test-planner → test-runner →
  bug-reporter → bug-fixer) in sequence, with gates between each phase.
  Everything is written to specs/<id>-<slug>/qa/.
tools: [view, bash_tool, grep_tool, glob_tool]
---

# QA cycle in this project

Canonical procedure for validating a feature after implementation. Closes the
loop: **test plan → execution → bug report → fix → PR**.

## Preconditions

- `specs/<id>-<slug>/spec.md` exists (the feature is specified)
- The feature has been implemented (production code exists)
- `make setup` has been run at least once
- Local test database is available
- Clean working tree (`git status` has no uncommitted changes)

## Automatic trigger

This skill is invoked automatically by the `.agent/hooks/post-tool-use.sh` hook
when `specs/<id>/tasks.md` is edited so that **all** checkboxes are checked
(`- [x]`) and `specs/<id>/qa/test-plan.md` does not yet exist.

The hook emits a message with the `[QA-CYCLE-TRIGGER]` prefix to stderr and uses
`exit 2` to ensure the agent reads and reacts. This is not an edit failure —
it is the signal that implementation is complete and the cycle must run before
any commit/push.

### Opt-out (rare)

If the feature legitimately does not need the cycle (e.g., spike, docs-only
change, pure refactor without testable behavior change), create:

```bash
mkdir -p specs/<id>-<slug>/qa
echo "reason: <one-line justification>" > specs/<id>-<slug>/qa/.skip-qa-cycle
```

The hook detects the file, records the justification in stderr, and releases
the agent. Use sparingly — the justification is versioned and reviewers see it.

## Inputs

- `SPEC_ID`: feature ID (e.g., `0001-health-check`)
- `BRANCH`: implementing branch (default: current branch)
- `MIN_SEVERITY` (optional): floor for the bug-fixer (`critical|high|medium|low`). Default: `low`.

## Step by step

### 0. Sanity check

```bash
test -d specs/$SPEC_ID || { echo "Spec not found"; exit 1; }
git status --porcelain || { echo "Dirty working tree"; exit 1; }
mkdir -p specs/$SPEC_ID/qa/logs
```

### 1. Plan — `test-planner`

Subagent: `test-planner`

Inputs:
- `SPEC_ID`
- `BRANCH`

Expected output: `specs/$SPEC_ID/qa/test-plan.md`

Advance gate:
- File exists
- Verdict = `PLAN_READY` **or** `PLAN_HAS_GAPS` (gaps **do not** block; they are informative)

If gaps are detected: show the `## Spec gaps detected` block to the human and
**ask** whether to continue anyway or pause to update the spec.

### 2. Execute — `test-runner`

Subagent: `test-runner`

Inputs:
- `SPEC_ID`
- `BRANCH`
- `LEVELS` (default: all — unit, integration, contract, e2e, security)

Expected output: `specs/$SPEC_ID/qa/test-results.md` + logs in `qa/logs/`

Advance gate:
- Verdict = `ALL_PASS` → **end the cycle here**. Do not invoke bug-reporter.
- Verdict = `FAILURES_DETECTED` → proceed to step 3.
- Verdict = `EXECUTION_ERROR` → **stop and escalate**. This is not a feature bug; it is a broken build.

### 3. Report — `bug-reporter`

Subagent: `bug-reporter`

Inputs:
- `SPEC_ID`
- `BRANCH`

Expected output: `specs/$SPEC_ID/qa/bug-report.md`

Advance gate:
- Verdict = `NO_BUGS` → anomalous scenario (test-runner saw failures but reporter did not): stop and escalate.
- Verdict = `BUGS_TO_FIX` → proceed to step 4.
- Verdict = `ESCALATE_TO_HUMAN` → stop. Show the report to the human.

### 4. Fix — `bug-fixer`

Subagent: `bug-fixer`

Inputs:
- `SPEC_ID`
- `BRANCH`
- `MIN_SEVERITY` (from cycle input)

Expected output: `specs/$SPEC_ID/qa/fix-log.md` + open PR

Advance gate:
- If any bug was marked `ESCALATED` or `ATTEMPTED_FAILED`: rerun steps 2–4 **at most 2 more times** (3 total iterations). If unresolved bugs remain after 3 cycles, stop and escalate to the human with the consolidated `fix-log.md`.

### 5. Re-verify — `test-runner` again

Rerun step 2 against the fix branch. Expect:
- `ALL_PASS` → cycle closed
- Remaining failures → all must be **the same** failures the `bug-fixer` marked as escalated. If **new** failures appear, the fix introduced a regression — stop and escalate.

### 6. Review — `reviewer` (optional, but recommended)

Subagent: `reviewer`

Inputs:
- `PR_BASE`
- `PR_HEAD`
- `SPEC_PATH=specs/$SPEC_ID`

Generates a PR review before the human looks at it.

### 7. Cross-check — `spec-verifier` (recommended)

Subagent: `spec-verifier`

Confirms that what remains on the branch **conforms to the spec** (no feature creep and no uncovered spec item).

## Final file structure

After a full cycle:

```
specs/<id>-<slug>/
├── spec.md
├── plan.md
├── tasks.md
└── qa/
    ├── test-plan.md       # from test-planner
    ├── test-results.md    # from test-runner
    ├── bug-report.md      # from bug-reporter
    ├── fix-log.md         # from bug-fixer
    └── logs/
        ├── lint.log
        ├── unit.log
        ├── integration.log
        ├── contract.log
        ├── security.log
        └── e2e.log
```

## Flow diagram

```
[implementation ready]
        │
        ▼
┌──────────────────┐    PLAN_READY
│  test-planner    │──────────────►  test-plan.md
└──────────────────┘
        │
        ▼
┌──────────────────┐    ALL_PASS
│  test-runner     │──────────────►  cycle ended
│                  │
│                  │    FAILURES_DETECTED
└──────┬───────────┘──────────────►  test-results.md
       │
       │  EXECUTION_ERROR
       └──────────────────────────►  escalate
       │
       ▼
┌──────────────────┐    NO_BUGS
│  bug-reporter    │──────────────►  anomaly
│                  │
│                  │    BUGS_TO_FIX
└──────┬───────────┘──────────────►  bug-report.md
       │
       │  ESCALATE_TO_HUMAN
       └──────────────────────────►  escalate
       │
       ▼
┌──────────────────┐
│  bug-fixer       │──────────────►  fix-log.md + open PR
└──────┬───────────┘                       │
       │                                   │
       │  loop ≤ 3                         │
       └─────────► test-runner ◄───────────┘
                       │
                       │  ALL_PASS
                       ▼
                 ┌──────────┐
                 │ reviewer │ + spec-verifier
                 └──────────┘
                       │
                       ▼
                 cycle ended
```

## Explicit gates

| From → To | Condition to advance |
|---|---|
| planner → runner | `test-plan.md` exists and has P0 cases |
| runner → reporter | verdict = `FAILURES_DETECTED` |
| runner → end | verdict = `ALL_PASS` |
| reporter → fixer | verdict = `BUGS_TO_FIX` |
| fixer → runner (re-run) | at least 1 bug with status `FIXED` in fix-log |
| any → escalate | execution error, spec ambiguity, new regression, or 3 iterations without convergence |

## Anti-patterns in this cycle

- **Do not skip the planner.** Without a plan, the runner has nothing to execute and the bug-reporter has no traceability.
- **Do not combine agents.** Each runs in isolated context to avoid contamination (planner should not see the report, fixer should not see the original plan — only the bug-report).
- **Do not run the cycle without a branch.** Always use an isolated branch (`fix/<spec-id>-qa-<ts>` is generated by the bug-fixer).
- **Do not hide escalated bugs.** If the cycle ends with `ESCALATED` bugs, the PR describes which ones and the human decides.
- **Do not silence flaky tests.** The bug-reporter marks `flaky: true`; the bug-fixer **cannot** simply add `t.Skip()`. Flaky becomes a tracked bug.

## When NOT to use this cycle

- **Spike / prototype** without a spec: do not run the cycle; it depends on the spec as oracle.
- **Docs-only / ADR change**: nothing to test.
- **Urgent hotfix**: run `bug-fixer` directly from a hand-written `bug-report.md` (by the human), skipping planner and runner. Document it in the commit.

## Summary commands

```bash
# Run the cycle manually, step by step
/spawn test-planner specs/0001-health-check
/spawn test-runner  specs/0001-health-check
/spawn bug-reporter specs/0001-health-check
/spawn bug-fixer    specs/0001-health-check MIN_SEVERITY=low

# Re-verification
/spawn test-runner  specs/0001-health-check
/spawn reviewer     PR_BASE=main PR_HEAD=$(git branch --show-current) SPEC_PATH=specs/0001-health-check
/spawn spec-verifier specs/0001-health-check
```

## Reference

- Subagents: `.agent/agents/{test-planner,test-runner,bug-reporter,bug-fixer}.md`
- Related subagents: `.agent/agents/{reviewer,spec-verifier,security-auditor}.md`
- Applicable rules: `.agent/rules/30-testing.md` (pyramid), `99-forbidden.md` (fixer limits)
- Constitution: `.agent/CONSTITUTION.md` (mandatory workflow)
