# Light Flow

For modifications, bug fixes, and feature additions to existing components.

**Triggers:** "add", "fix", "modify", "update", "enhance", "extend"

## Step 1: Understand

Read target files. Understand: what it does, public API, current verification state, how modification fits.

## Step 2: Clarify Scope

Ask: what changes? what should NOT change? existing tests to update?

Produce modification summary:
```
Modification: [one sentence]
Files affected: [list]
Behavior change: [what changes]
Risk: [what could break]
```

## Step 3: Verification + TDD

Define: test(s) to write first (RED), how to verify fix works, regression check.

## Step 4: Implement TDD

RED → write failing test. GREEN → minimal code to pass. VERIFY → run verification.

One test → one fix → verify → repeat.

## Step 5: Review

Read `knowledge/review-framework.md`. Review against `knowledge/coding-standards.md` and modification summary.

## Step 6: Verify Completion

- Modification requirements met
- TDD tests pass
- Review verdict pass or pass-with-nits
