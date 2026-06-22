# Review Framework

## Verdict

Review output starts with a verdict:

- **pass**: No blocking issues, ready to ship
- **pass-with-nits**: Minor suggestions, non-blocking
- **changes-required**: Blocking issues found, must fix before completion
- **blocked**: Cannot proceed without user decision (missing spec, ambiguous requirement)

## Finding Categories

### Blocking Correctness Issues
Issues that will cause simulation failures, data corruption, or protocol violations.

### Methodology Issues
Violations of UVM best practices that cause maintainability or reuse problems.
- Wrong phase usage
- Missing factory registration
- Improper config_db usage
- TLM connection errors
- Objection handling errors

### API/Design Issues
Interface design problems that affect usability or reusability.
- Inconsistent naming
- Leaking implementation details
- Missing or unclear public API
- Poor parameterization

### Verification Gaps
Missing or insufficient verification coverage.
- Test cases not defined
- Edge cases not covered
- Non-runnable environment not reported

### Maintainability Suggestions
Non-blocking suggestions for long-term code health.
- Code organization
- Comment quality
- Duplication
- Complexity

## Finding Format

Each finding must include:
- **Location**: file path and line number
- **Issue**: what is wrong
- **Why it matters**: why this is important in SV/UVM context
- **Fix**: suggested fix
- **Blocking**: yes/no

## Review Checklist Reference

The reviewer applies the following checks (domain-specific checks are in each skill's references):

1. UVM component structure correct
2. Factory registration present
3. Config_db usage type-safe
4. Phase behavior correct
5. Objection handling correct
6. TLM connections clear
7. Transaction lifecycle safe (copy/clone/randomize)
8. Driver/monitor/sequencer responsibilities separated
9. Scoreboard can observe correct behavior
10. API is usable and stable
11. Verification coverage defined
12. No race conditions or implicit timing assumptions
13. **Assertion verification** (if assertions are present):
    - Assertions use proper timing conditions
    - Assertions are tested and verified to work
    - Verification script checks for assertion errors
    - No false passes due to assertion error reporting
