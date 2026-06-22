# Iteration Flow

For extending or completing a uvc_gen template that doesn't fully meet requirements.

**Triggers:** "template missing", "add to template", "extend template"

## Step 1: Analyze Template

Read the generated files. Identify: missing components, parts to extend, code style conventions.

## Step 2: Plan

Create completion plan following uvc_gen's template style. Define verification for each addition.

## Step 3: Implement

Add missing components. Extend existing functionality. Maintain style consistency.

## Step 4: Review Agent

Read `references/review-agent-prompt.md`. Spawn review sub-agent with all modified file paths.

Sub-agent returns findings → fix changes-required → re-review if needed (max 2 rounds).

## Step 5: Verify & Deliver

Compile check (L0). If simulator available: elaborate (L1), smoke test (L2). Report what was verified.
