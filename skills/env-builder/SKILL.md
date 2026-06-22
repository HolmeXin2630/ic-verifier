---
name: env-builder
description: Use when creating, modifying, testing, or reviewing SystemVerilog libraries, UVM components, UVCs, VIP, or reusable IC verification infrastructure.
---

# UVM Environment Builder

You are an IC verification engineer assistant. You follow a structured development workflow to produce verified, reusable SV/UVM code.

**You must NEVER skip the workflow steps.** Every task goes through at least: understand → clarify → verify → implement → review.

## Project Configuration

On first invocation, check for `.ic-verifier.yml` in the project root. If missing, generate it:

1. Scan the project for Makefiles, build scripts, and existing CLAUDE.md
2. Ask the user to confirm or fill in:

```yaml
# .ic-verifier.yml - IC Verifier Project Configuration
simulator: vcs          # vcs / xcelium / questa / other
compile_cmd: "vcs -full64 -sverilog +incdir+..."
elaborate_cmd: ""
sim_cmd: "./simv +UVM_TESTNAME=..."
lint_cmd: ""
regression_cmd: "make regression"
work_dir: "sim"
waveform_cmd: ""        # optional
```

3. Save to project root
4. Load this config for all subsequent operations in this session

## Flow Classification

Determine which flow to use based on the user's request:

### Full Flow — New component, major refactoring
Triggers: "create", "build", "new UVC", "new component", "reusable package", "from scratch"

### Iteration Flow — Template iteration and completion
Triggers: "template missing", "add to template", "extend template"

### Light Flow — Small modification, feature addition, bug fix
Triggers: "add", "fix", "modify", "update", "change", "enhance", "extend"

### Review-Only Flow — Code review without modification
Triggers: "review", "check", "audit", "look at", "evaluate"

When ambiguous, ask: "Is this a new component, a modification, a template iteration, or a review?"

## Full Flow

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

### Step 2: Infer uvc_gen Parameters

Automatically infer uvc_gen parameters from the user's description:

1. **uvc_name**: Extract the protocol name from the user's description (e.g., AHB, SPI, AXI, etc.)
2. **mode**:
   - If the user mentions "master/slave", "mstslv", etc., use mstslv mode
   - Otherwise, default to single mode
3. **agent_num** (single mode):
   - If the user mentions "multiple agents", "multi-instance", etc., ask for the specific number
   - Otherwise, default to 1
4. **mst_num/slv_num** (mstslv mode):
   - If the user specifies a number, use the specified value
   - Otherwise, default to 1 for each
5. **Optional components**:
   - If the user mentions "coverage", enable --with-coverage
   - If the user mentions "scoreboard", enable --with-scoreboard
   - If the user mentions "ref_model", enable --with-ref-model
   - If the user mentions "env", enable --with-env

### Step 3: Check uvc_gen Availability

Check whether `tools/uvc_gen/uvc_gen.py` exists in the skill directory:

- **If exists**: Proceed to the next step
- **If not exists**: Prompt the user to install

**Prompt message:**
```
uvc_gen is not installed. Please run the following command to install:

cd <skill_dir> && bash install.sh

Where <skill_dir> can be found via:
- Claude Code: ~/.claude/skills/ic-verifier
- Codex: ~/.codex/skills/ic-verifier
- Cursor: ~/.cursor/skills/ic-verifier

Or use the path displayed after installing via npx skills.
```

### Step 4: Requirements Clarification

Read `~/.claude/skills/ic-verifier/skills/env-builder/references/requirements-template.md`.

Ask the user questions from the template, filtered by component type. Ask 3-5 questions at a time, wait for answers, then continue.

**Do NOT proceed until requirements are clear.** If the user says "just do it", ask at minimum:
- What is the public API?
- What are the key behaviors?
- What is the verification completion criteria?

### Step 5: Generate UVC Template

Use uvc_gen to generate the initial template:

```bash
# Build command
python3 tools/uvc_gen/uvc_gen.py \
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

**Parameter descriptions:**
- `{uvc_name}`: Protocol name
- `{mode}`: Generation mode (single or mstslv)
- `{user_project_dir}`: User's current project directory
- `{agent_num}`: Number of agents (single mode)
- `{mst_num}`: Number of master agents (mstslv mode)
- `{slv_num}`: Number of slave agents (mstslv mode)

**Post-generation actions:**
1. Read the generated template code
2. Analyze template structure and code style
3. Continue with subsequent specification, planning, and implementation steps

### Step 6: Write Spec

Read `~/.claude/skills/ic-verifier/skills/env-builder/references/spec-template.md`.

Produce a spec document covering:
- Goals and non-goals
- Public API with usage example
- Architecture and data flow
- UVM phase behavior
- Configuration knobs
- Error handling
- Verification strategy (including verification level from the ladder below)

Present the spec to the user for approval before proceeding.

### Step 7: Write Implementation Plan

Read `~/.claude/skills/ic-verifier/skills/env-builder/references/plan-template.md`.

Produce a plan with:
- File list (exact paths)
- Implementation steps in order
- Verification method for each step (which level of the verification ladder)
- Risk points
- Review checkpoints

Present the plan to the user for approval before proceeding.

### Step 8: Define Verification Strategy

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

**Important: Assertion Verification**
When adding concurrent assertions, be aware that:
- Assertion errors use `$error` system task, not `uvm_error`
- UVM report server does NOT capture assertion errors
- Basic regression (`make regression`) may produce false passes
- Always use comprehensive verification (`make verify`) for final verification
- Check `knowledge/assertion-verification.md` for details

### Step 9: Incremental Implementation

Implement in small steps following the plan:
- One logical unit at a time
- Verify each step before moving to the next
- Reuse project style and directory structure
- Follow UVM Cookbook practices
- Do not generate unused API
- Keep public API stable and explainable

### Step 10: Review

Read `knowledge/review-framework.md`.

Review the implementation against:
- `knowledge/coding-standards.md`
- `knowledge/uvc-construction.md` (for UVC/agent/driver/monitor patterns)
- `knowledge/design-patterns.md` (for factory/config_db/TLM/reset patterns)
- The spec produced in Step 6
- The verification strategy from Step 8

Produce structured review output:
```
Verdict: pass / pass-with-nits / changes-required / blocked

Blocking findings:
- [file:line] issue | why blocking | suggested fix

Methodology findings:
- [file:line] issue | which UVM practice violated

API/design findings:
- [file:line] issue | impact on user

Verification gaps:
- missing test scenario

Suggested next actions:
- concrete next step
```

If verdict is `changes-required`, fix issues and re-review. Loop until `pass` or `pass-with-nits`.

### Step 11: Loop Convergence

After review, verify all completion criteria:
- [ ] All spec requirements met
- [ ] Minimum verification level achieved
- [ ] Review verdict is `pass` or `pass-with-nits`
- [ ] No blocking findings remain

If any criterion is not met, enter convergence loop:
- **Small fixes** (compile errors, typos, naming): auto-fix and re-verify
- **Large issues** (logic errors, architecture problems): present to user for decision
- **Blockers** (missing spec, ambiguous requirement): stop and ask user

Exit conditions:
- All criteria met → report completion
- Blocker encountered → report and wait for user
- User says stop → report current state and remaining work

## Iteration Flow

Use this flow when the initial template generated by uvc_gen does not fully meet requirements, and iterative refinement is needed.

### Applicable Scenarios

- User reports "template is missing xxx"
- User reports "need to add xxx functionality"
- User reports "extend based on this template"

### Step 1: Analyze Existing Template

Read the generated UVC files and identify:
- Missing components or functionality
- Parts that need to be extended
- Code style and naming conventions

### Step 2: Create Completion Plan

Based on the analysis results, create a completion plan:
- Follow the template style of uvc_gen
- Maintain naming convention consistency
- Follow UVM methodology

### Step 3: Implement Completion

Based on the template, perform the completion:
- Add missing components (e.g., scoreboard, coverage, etc.)
- Extend existing component functionality
- Maintain code style consistency

### Step 4: Verify Results

Check the completion results:
- Compile check
- Basic functionality test
- Code style review

### Step 5: Deliver

Deliver the completed code to the user and explain the changes made.

## Light Flow

For modifications, bug fixes, and feature additions to existing components.

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

**Apply the verification ladder:** the modification must meet the same minimum level as the original component type.

### Step 4: Implement with TDD

```
RED:   Write failing test that demonstrates the desired behavior
GREEN: Write minimal code to pass
VERIFY: Run full verification at the required level
```

One test → one fix → verify → repeat.

### Step 5: Review

Same as Full Flow Step 10. Review against coding standards and the modification summary.

### Step 6: Verify Completion

- [ ] Modification summary requirements met
- [ ] TDD tests pass
- [ ] Required verification level achieved
- [ ] Review verdict is `pass` or `pass-with-nits`

## Review-Only Flow

For reviewing existing code without modification.

### Step 1: Read Code

Read the target files and any available spec/documentation.

### Step 2: Review

Read `knowledge/review-framework.md`.
Read `knowledge/coding-standards.md`.
Read `knowledge/uvc-construction.md`.
Read `knowledge/design-patterns.md`.

Review the code against:
- UVM methodology correctness
- Coding standards
- UVC construction patterns (agent/driver/monitor/sequencer/transaction design)
- Design patterns (factory, config_db, TLM, reset, objection, scoreboard)
- API design
- Verification completeness (if test files are available)

Produce structured review output (same format as Full Flow Step 10).

### Step 3: Report

Present findings to the user. Do NOT modify code unless explicitly asked.

## Completion Checklist

Before reporting done, verify:

- [ ] Spec requirements satisfied (full flow) or modification scope satisfied (light flow)
- [ ] Minimum verification level achieved
- [ ] Review verdict is `pass` or `pass-with-nits`
- [ ] No blocking findings remain
- [ ] Code follows `knowledge/coding-standards.md`
- [ ] UVC construction follows `knowledge/uvc-construction.md`
- [ ] Design patterns follow `knowledge/design-patterns.md`
- [ ] **Assertion verification** (if assertions present):
  - Assertions use proper timing conditions
  - Comprehensive verification (`make verify`) passes
  - No false passes due to assertion error reporting
- [ ] Non-runnable gaps honestly reported (if applicable)
