# [Component Name] Implementation Plan

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| my_component.sv | Create | Main component class |
| my_component_pkg.sv | Create | Package file |
| my_transaction.sv | Create | Transaction class |

## Implementation Steps

### Step 1: [Step Name]

**What:** Description of what this step does.
**Files:** `path/to/file.sv`
**Verification:** How to verify this step is correct.
**Risk:** What could go wrong.

- [ ] Implement
- [ ] Verify (compile / elaborate / simulate)
- [ ] Review checkpoint

### Step 2: [Step Name]

...

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Interface mismatch | Medium | High | Verify interface first |
| Phase ordering | Low | Medium | Follow UVM cookbook |

## Review Checkpoints

After which steps should review agent be invoked?
- After step N: first compilable version
- After step M: first simulation-ready version
- After step P: final version before handoff
