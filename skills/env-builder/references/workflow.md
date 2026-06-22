# Workflow Detail

This file contains the detailed steps for each flow. SKILL.md decides which flow to use; this file describes how to execute it.

All paths in this file are relative to the **skill directory** (where SKILL.md lives).

---

## Full Flow

For new components, major refactoring, or building from scratch.

### Step 1: Classify Component Type

Identify the component type from the user's request:
- UVC / VIP
- UVM agent
- driver / monitor / sequencer
- sequence library
- transaction / config object
- scoreboard / subscriber / coverage collector
- register adapter / RAL integration
- reusable SV package
- protocol-independent utility library

This classification determines which questions to ask, which knowledge files to load, and whether uvc_gen is applicable.

### Step 2: Requirements Clarification

Read `references/requirements-template.md`.

Ask the user questions from the template, filtered by component type. Ask 3-5 questions at a time, wait for answers, then continue.

**Do NOT proceed until requirements are clear.** If the user says "just do it", ask at minimum:
- What is the public API?
- What are the key behaviors?
- What is the verification completion criteria?

### Step 3: Generate UVC Template (UVC/VIP only)

**This step only applies when the component type is UVC or VIP.** For all other types, skip to Step 4.

#### 3a: Infer uvc_gen Parameters

Automatically infer uvc_gen parameters from the user's description:

1. **uvc_name**: Extract the protocol name (e.g., AHB, SPI, AXI)
2. **mode**:
   - "master/slave", "mstslv" → mstslv mode
   - Otherwise → single mode
3. **agent_num** (single mode): default 1, unless user specifies multiple
4. **mst_num/slv_num** (mstslv mode): default 1 each, unless user specifies
5. **Optional components**: enable flags based on user mentions:
   - "coverage" → `--with-coverage`
   - "scoreboard" → `--with-scoreboard`
   - "ref_model" → `--with-ref-model`
   - "env" → `--with-env`

#### 3b: Check uvc_gen Availability

Find `uvc_gen.py` by checking these locations in order:
1. `tools/uvc_gen/uvc_gen.py` (relative to skill directory)
2. `../../ic-verifier/tools/uvc_gen/uvc_gen.py` (shared tools directory)

If not found, prompt the user:
```
uvc_gen is not installed. Run: cd <ic-verifier-dir> && bash install.sh
```

#### 3c: Generate Template

```bash
python3 <uvc_gen_path> \
    -n {uvc_name} \
    -m {mode} \
    -v v1.0 \
    -o {user_project_dir} \
    --agent-num {agent_num} \
    --mst-num {mst_num} \
    --slv-num {slv_num} \
    [--with-coverage] \
    [--with-scoreboard] \
    [--with-ref-model] \
    [--with-env]
```

After generation:
1. Read the generated template code
2. Analyze template structure and code style
3. Continue with subsequent steps

### Step 4: Write Spec

Read `references/spec-template.md`.

Produce a spec document covering:
- Goals and non-goals
- Public API with usage example
- Architecture and data flow
- UVM phase behavior
- Configuration knobs
- Error handling
- Verification strategy (including verification level from the ladder)

Present the spec to the user for approval before proceeding.

### Step 5: Write Implementation Plan

Read `references/plan-template.md`.

Produce a plan with:
- File list (exact paths)
- Implementation steps in order
- Verification method for each step (which level of the verification ladder)
- Risk points
- Review checkpoints

Present the plan to the user for approval before proceeding.

### Step 6: Define Verification Strategy

Before writing any code, define how each piece will be verified.

**Verification Ladder:**

| Level | Name | What | How |
|-------|------|------|-----|
| L0 | Compile | Code compiles without errors | `vcs -compile` or equivalent |
| L1 | Elaborate | No unresolved references | `vcs -elaborate` or equivalent |
| L2 | Smoke | Minimal testbench, basic transaction flow | Simple test with 1-2 transactions |
| L3 | Functional | Key behaviors covered by tests | Directed + constrained random tests |
| L4 | Edge Cases | Error injection, corner cases, stress | Boundary conditions, error scenarios |

**Minimum verification by component type:**

| Component Type | Minimum | Recommended |
|---------------|---------|-------------|
| SV utility library | L0 + unit tests | L0 + L3 |
| UVM component | L0 + L1 + L2 | L0-L3 |
| UVC / VIP | L0 + L1 + L2 | L0-L4 |
| RAL adapter | L0 + L1 + mapping test | L0-L3 |
| scoreboard | L0 + L1 + expectation test | L0-L3 |

**Non-runnable environment:** If no simulator is available, report honestly:
- What verification was possible (compile check, static review)
- What verification was NOT possible (simulation, functional tests)
- What risks this creates

**AI cannot claim completion without meeting the minimum verification level.**

**Assertion Verification:** When adding concurrent assertions, be aware that assertion errors use `$error` (not `uvm_error`), UVM report server does NOT capture them, and basic regression may produce false passes. Check `knowledge/assertion-verification.md` for details.

### Step 7: Incremental Implementation

Implement in small steps following the plan:
- One logical unit at a time
- Verify each step before moving to the next
- Reuse project style and directory structure
- Follow UVM Cookbook practices
- Do not generate unused API
- Keep public API stable and explainable

### Step 8: Review

Read `knowledge/review-framework.md`.

Review the implementation against:
- `knowledge/coding-standards.md`
- `knowledge/uvc-construction.md` (for UVC/agent/driver/monitor patterns)
- `knowledge/design-patterns.md` (for factory/config_db/TLM/reset patterns)
- The spec produced in Step 4
- The verification strategy from Step 6

Produce structured review output following the format in `knowledge/review-framework.md`.

If verdict is `changes-required`, fix issues and re-review. Loop until `pass` or `pass-with-nits`.

### Step 9: Loop Convergence

After review, verify all completion criteria:
- All spec requirements met
- Minimum verification level achieved
- Review verdict is `pass` or `pass-with-nits`
- No blocking findings remain

If any criterion is not met, enter convergence loop:
- **Small fixes** (compile errors, typos, naming): auto-fix and re-verify
- **Large issues** (logic errors, architecture problems): present to user for decision
- **Blockers** (missing spec, ambiguous requirement): stop and ask user

Exit conditions:
- All criteria met → report completion
- Blocker encountered → report and wait for user
- User says stop → report current state and remaining work

---

## Iteration Flow

For extending or completing a uvc_gen-generated template that doesn't fully meet requirements.

**Triggers:** "template missing", "add to template", "extend template", "template is missing xxx"

### Step 1: Analyze Existing Template

Read the generated UVC files and identify:
- Missing components or functionality
- Parts that need to be extended
- Code style and naming conventions used by uvc_gen

### Step 2: Create Completion Plan

Based on the analysis:
- Follow uvc_gen's template style and naming conventions
- Identify what needs to be added vs. extended
- Define verification for each addition (apply the verification ladder)

### Step 3: Implement Completion

- Add missing components (e.g., scoreboard, coverage)
- Extend existing component functionality
- Maintain code style consistency with the generated template

### Step 4: Review

Read `knowledge/review-framework.md`.

Review the completion against:
- `knowledge/coding-standards.md`
- `knowledge/uvc-construction.md`
- `knowledge/design-patterns.md`
- The original requirements

Produce structured review output following the format in `knowledge/review-framework.md`.

Fix any `changes-required` findings and re-review.

### Step 5: Verify and Deliver

- Compile check (L0)
- If simulator available: elaborate (L1) and smoke test (L2)
- Report what was verified and what was not

Deliver the completed code to the user and explain the changes made.

---

## Light Flow

For modifications, bug fixes, and feature additions to existing components.

**Triggers:** "add", "fix", "modify", "update", "change", "enhance", "extend"

### Step 1: Understand Existing Code

Read the target files. Understand:
- What the component does
- Its public API
- Its current verification state
- How the modification fits in

### Step 2: Clarify Modification Scope

Ask the user:
- What specifically needs to change?
- What should NOT change?
- Are there existing tests that need updating?

Produce a brief modification summary (not a full spec):
```
Modification: [one sentence]
Files affected: [list]
Behavior change: [what changes from the user's perspective]
Risk: [what could break]
```

### Step 3: Define Verification + TDD

For the modification, define:
- What test(s) to write first (TDD red)
- How to verify the fix works
- How to verify nothing else broke (regression)

Apply the verification ladder: the modification must meet the same minimum level as the original component type.

### Step 4: Implement with TDD

```
RED:   Write failing test that demonstrates the desired behavior
GREEN: Write minimal code to pass
VERIFY: Run full verification at the required level
```

One test → one fix → verify → repeat.

### Step 5: Review

Read `knowledge/review-framework.md`.

Review against:
- `knowledge/coding-standards.md`
- The modification summary from Step 2

Produce structured review output. Fix any `changes-required` findings.

### Step 6: Verify Completion

- Modification summary requirements met
- TDD tests pass
- Required verification level achieved
- Review verdict is `pass` or `pass-with-nits`

---

## Review-Only Flow

For reviewing existing code without modification.

**Triggers:** "review", "check", "audit", "look at", "evaluate"

### Step 1: Read Code

Read the target files and any available spec/documentation.

### Step 2: Review

Read these knowledge files:
- `knowledge/review-framework.md`
- `knowledge/coding-standards.md`
- `knowledge/uvc-construction.md`
- `knowledge/design-patterns.md`

Review the code against:
- UVM methodology correctness
- Coding standards
- UVC construction patterns (agent/driver/monitor/sequencer/transaction design)
- Design patterns (factory, config_db, TLM, reset, objection, scoreboard)
- API design
- Verification completeness (if test files are available)

Produce structured review output following the format in `knowledge/review-framework.md`.

### Step 3: Report

Present findings to the user. Do NOT modify code unless explicitly asked.
