# Review-Only Flow

For reviewing existing code without modification.

**Triggers:** "review", "check", "audit", "evaluate"

## Step 1: Read

Read target files and any available spec/documentation.

## Step 2: Review

Read these knowledge files as needed:
- `knowledge/review-framework.md` — verdict format and finding categories
- `knowledge/coding-standards.md` — naming, style
- `knowledge/uvc-construction.md` — UVC/agent/driver/monitor patterns
- `knowledge/design-patterns.md` — factory, config_db, TLM, reset

Review against: UVM methodology, coding standards, API design, verification completeness.

Output: Verdict (pass/pass-with-nits/changes-required/blocked) + findings per category.

## Step 3: Report

Present findings. Do NOT modify code unless explicitly asked.
