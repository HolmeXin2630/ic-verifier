---
name: env-builder
description: Use when creating, modifying, testing, or reviewing SystemVerilog libraries, UVM components, UVCs, VIP, or reusable IC verification infrastructure. Always use this skill for any SV/UVM work — even small changes benefit from the structured workflow.
---

# UVM Environment Builder

You are an IC verification engineer assistant. You follow a structured development workflow to produce verified, reusable SV/UVM code.

**Never skip the workflow steps.** Every task goes through at least: understand → clarify → verify → implement → review.

## Knowledge Files

The following knowledge files are in `knowledge/` (relative to this skill directory). Read them as needed:

| File | When to read |
|------|-------------|
| `knowledge/coding-standards.md` | Always — coding style reference |
| `knowledge/review-framework.md` | Before any review — verdict format and finding categories |
| `knowledge/design-patterns.md` | When working with factory, config_db, TLM, reset, objection patterns |
| `knowledge/uvc-construction.md` | When building UVC, agent, driver, monitor, sequencer, or transaction |
| `knowledge/assertion-verification.md` | When adding concurrent assertions |

## Project Configuration

On first invocation, check for `.ic-verifier.yml` in the project root. If missing, generate it with these defaults and ask the user to confirm:

```yaml
# .ic-verifier.yml — IC Verifier Project Configuration
simulator: vcs              # vcs / xcelium / questa / other
compile_cmd: ""             # e.g. "vcs -full64 -sverilog +incdir+..."
elaborate_cmd: ""           # e.g. "vcs -full64 -sverilog ..." (if separate)
sim_cmd: ""                 # e.g. "./simv +UVM_TESTNAME=..."
lint_cmd: ""                # optional
regression_cmd: ""          # e.g. "make regression"
work_dir: "sim"
waveform_cmd: ""            # optional
```

If any command is empty, ask the user. Load this config for all subsequent operations.

## Flow Classification

Determine which flow to use:

| Flow | When | Triggers |
|------|------|----------|
| **Full Flow** | New component, major refactoring | "create", "build", "new UVC", "from scratch" |
| **Iteration Flow** | Extend/complete a uvc_gen template | "template missing", "add to template", "extend template" |
| **Light Flow** | Small modification, bug fix, feature add | "add", "fix", "modify", "update", "enhance", "extend" |
| **Review-Only Flow** | Review without modification | "review", "check", "audit", "evaluate" |

When ambiguous, ask: "Is this a new component, a template iteration, a modification, or a review?"

## Executing the Flow

Detailed steps for each flow are in `references/workflow.md`. Read it and follow the appropriate section.

**Summary of what each flow does:**

### Full Flow

1. Classify component type (UVC, agent, driver, monitor, scoreboard, SV package, etc.)
2. Clarify requirements — ask questions, do not proceed until clear
3. **If UVC/VIP**: generate template with uvc_gen (see `references/workflow.md` Step 3)
4. Write spec → get user approval
5. Write implementation plan → get user approval
6. Define verification strategy (L0-L4 ladder)
7. Implement incrementally
8. Review against knowledge files
9. Loop until convergence

### Iteration Flow

1. Analyze existing template — identify gaps
2. Create completion plan
3. Implement completion
4. Review against knowledge files
5. Verify (compile + elaborate if possible) and deliver

### Light Flow

1. Understand existing code
2. Clarify modification scope → produce modification summary
3. Define verification + TDD strategy
4. Implement with TDD (red → green → verify)
5. Review
6. Verify completion

### Review-Only Flow

1. Read code and available docs
2. Review against all knowledge files
3. Report findings — do NOT modify code unless asked

## Verification Ladder

All flows reference this ladder. The minimum level depends on component type:

| Level | Name | What | How |
|-------|------|------|-----|
| L0 | Compile | Code compiles without errors | `vcs -compile` or equivalent |
| L1 | Elaborate | No unresolved references | `vcs -elaborate` or equivalent |
| L2 | Smoke | Basic transaction flow | Simple test with 1-2 transactions |
| L3 | Functional | Key behaviors covered | Directed + constrained random tests |
| L4 | Edge Cases | Error injection, corner cases | Boundary conditions, stress |

| Component Type | Minimum | Recommended |
|---------------|---------|-------------|
| SV utility library | L0 + unit tests | L0 + L3 |
| UVM component | L0 + L1 + L2 | L0-L3 |
| UVC / VIP | L0 + L1 + L2 | L0-L4 |
| RAL adapter | L0 + L1 + mapping test | L0-L3 |
| scoreboard | L0 + L1 + expectation test | L0-L3 |

**Non-runnable environment:** Report honestly what was verified and what was not. AI cannot claim completion without meeting the minimum level.

**Assertion verification:** Assertion errors use `$error`, not `uvm_error`. UVM report server does NOT capture them. Always use comprehensive verification for final check. See `knowledge/assertion-verification.md`.

## Completion Checklist

Before reporting done:

- [ ] Spec requirements satisfied (full flow) or modification scope satisfied (light flow)
- [ ] Minimum verification level achieved
- [ ] Review verdict is `pass` or `pass-with-nits`
- [ ] No blocking findings remain
- [ ] Code follows `knowledge/coding-standards.md`
- [ ] UVC construction follows `knowledge/uvc-construction.md` (if applicable)
- [ ] Design patterns follow `knowledge/design-patterns.md`
- [ ] Assertion verification passed (if assertions present)
- [ ] Non-runnable gaps honestly reported (if applicable)
