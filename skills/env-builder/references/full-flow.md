# Full Flow

For new components, major refactoring, or building from scratch.

## Step 1: Classify Component Type

Identify from the user's request: UVC/VIP, agent, driver, monitor, sequencer, sequence library, transaction, scoreboard, register adapter, SV package, utility library.

## Step 2: Requirements Clarification

Read `references/requirements-template.md`. Ask questions filtered by component type. Ask 3-5 at a time, wait for answers.

**Do NOT proceed until requirements are clear.** If user says "just do it", ask at minimum:
- What is the public API?
- What are the key behaviors?
- Verification completion criteria?

## Step 3: Generate UVC Template (UVC/VIP only)

**Skip this step for non-UVC types.**

Infer uvc_gen parameters: uvc_name (protocol name), mode (single/mstslv), agent_num, optional components (--with-coverage, --with-scoreboard, --with-env).

Check uvc_gen availability: look for `tools/uvc_gen/uvc_gen.py` in skill directory. If not found:
```bash
mkdir -p <skill-dir>/tools && git clone --depth 1 https://github.com/HolmeXin2630/uvc_gen.git <skill-dir>/tools/uvc_gen
pip3 install jinja2 rich
```

Generate: `python3 tools/uvc_gen/uvc_gen.py -n {name} -m {mode} -v v1.0 -o {project_dir} [--with-env]`

After generation: read the generated files, analyze structure and style.

## Step 4: Write Spec

Read `references/spec-template.md`. Produce spec covering: goals/non-goals, public API, architecture, data flow, UVM phase behavior, config knobs, error handling, verification strategy.

Present to user for approval.

## Step 5: Write Plan

Read `references/plan-template.md`. Produce plan with: file list, implementation steps, verification method per step, risk points, review checkpoints.

Present to user for approval.

## Step 6: Verification Strategy

Define verification level per component:

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| SV utility | L0 + unit tests | L0 + L3 |
| UVM component | L0 + L1 + L2 | L0-L3 |
| UVC / VIP | L0 + L1 + L2 | L0-L4 |

Ladder: L0=Compile, L1=Elaborate, L2=Smoke, L3=Functional, L4=Edge Cases.

Non-runnable environment: report honestly what was verified and what was not.

## Step 7: Implement

One logical unit at a time. Verify each step before next. Follow UVM Cookbook practices.

## Step 8: Review Agent

Read `references/review-agent-prompt.md` for the sub-agent prompt template.

Spawn a review sub-agent: fill in `{file_list}` with all generated/modified file paths, call Agent tool with the filled prompt.

The sub-agent will read shared knowledge files and return structured findings.

After sub-agent returns:
- **pass / pass-with-nits** → proceed to Step 9
- **changes-required** → fix blocking findings, re-spawn review-agent (max 2 re-reviews)
- **blocked** → report to user, wait for decision

## Step 9: Convergence

Check: all spec requirements met? minimum verification level? review pass? no blocking findings?

Small fixes → auto-fix. Large issues → ask user. Blockers → stop and ask.
