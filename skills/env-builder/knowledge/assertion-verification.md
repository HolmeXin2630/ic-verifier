# Assertion Verification Guide

## Problem: False Pass with Assertions

When adding concurrent assertions to a design, it's possible to get a "false pass" where:
- UVM reports `UVM_ERROR: 0` and `UVM_FATAL: 0`
- But assertion errors are still present in the simulation output

This happens because assertion errors are reported through `$error` system tasks, which are **not captured by UVM's report server**.

## Root Cause

### UVM Error Reporting
```systemverilog
// UVM errors are captured by the report server
`uvm_error("TAG", "Error message")
// Shows up in: UVM Report Summary
// Captured by: UVM_ERROR count
```

### Assertion Error Reporting
```systemverilog
// Assertion errors use $error system task
assert property (my_property)
    else $error("Assertion failed");
// Shows up in: Simulation output (stderr/stdout)
// NOT captured by: UVM_ERROR count
```

## Verification Strategy

### 1. Check ALL Error Types

When verifying simulations, check for **all** error types:

```bash
# Check for UVM errors
grep "UVM_ERROR" output.log | grep -v "UVM_ERROR :    0"

# Check for UVM fatals
grep "UVM_FATAL" output.log | grep -v "UVM_FATAL :    0"

# Check for assertion errors (VCS)
grep "Error:.*assert" output.log

# Check for general simulation errors
grep "^Error:" output.log

# Check for VCS-specific errors
grep "Failed to obtain license" output.log
```

### 2. Use Comprehensive Verification Script

Use the `verify_regression.sh` script that checks for all error types:

```bash
# Run comprehensive verification
make verify

# Or run directly
./verify_regression.sh
```

### 3. Manual Verification

For critical changes, manually check the full simulation output:

```bash
# Run test and save full output
make run TEST=apb_smoke_test 2>&1 | tee full_output.log

# Check for any errors
grep -i error full_output.log
grep -i warning full_output.log
```

## Assertion Best Practices

### 1. Use Proper Assertion Severity

```systemverilog
// Use $error for non-critical assertion failures
assert property (my_property)
    else $error("Non-critical assertion failed");

// Use $fatal for critical assertion failures
assert property (critical_property)
    else $fatal("Critical assertion failed");
```

### 2. Add Assertion Coverage

```systemverilog
// Track assertion coverage
property my_property;
    @(posedge clk) req |-> ##[1:3] ack;
endproperty

assert property (my_property)
    else $error("Assertion failed");

// Coverage for assertion
cover property (my_property);
```

### 3. Test Assertions Thoroughly

After adding assertions, verify they work correctly:

```bash
# Run test with assertion checking
make run TEST=apb_smoke_test 2>&1 | grep -E "(Error|assert|failed)"

# Check for assertion errors specifically
make run TEST=apb_smoke_test 2>&1 | grep "Error:.*assert"
```

## Development Flow Update

### Step 1: Add Assertions
- Add concurrent assertions to interface or design
- Use proper assertion properties
- Add assertion coverage if needed

### Step 2: Verify Assertions Work
- Run simulation with assertions enabled
- Check for assertion errors in output
- Verify assertions are triggered correctly
- **DO NOT** rely solely on UVM error counts

### Step 3: Comprehensive Verification
- Use `make verify` for comprehensive checking
- Check for ALL error types (UVM, assertion, simulation)
- Verify no false passes

### Step 4: Regression Testing
- Run full regression with comprehensive checking
- Verify all tests pass without any errors
- Document assertion coverage

## Common Pitfalls

### ❌ Pitfall 1: Relying Only on UVM Errors
```bash
# WRONG - misses assertion errors
grep "UVM_ERROR :    0" output.log
```

### ❌ Pitfall 2: Incomplete Error Checking
```bash
# WRONG - only checks some error types
grep -E "(UVM_ERROR|UVM_FATAL)" output.log
```

### ✅ Correct: Comprehensive Error Checking
```bash
# CORRECT - checks all error types
grep -E "(Error|UVM_ERROR|UVM_FATAL|failed)" output.log
```

## Verification Checklist

After adding assertions, verify:

- [ ] Assertions compile without errors
- [ ] Assertions are properly triggered
- [ ] No false passes in simulation
- [ ] All error types are checked
- [ ] Comprehensive verification script passes
- [ ] Full regression passes

## Tools and Scripts

### verify_regression.sh
Comprehensive verification script that checks for:
- UVM errors and fatals
- Assertion errors
- Simulation errors
- License errors
- Compilation errors

### Usage
```bash
# Run comprehensive verification
make verify

# Or run directly
./verify_regression.sh
```

## Conclusion

When adding assertions to a design:

1. **Never rely solely on UVM error counts**
2. **Always check for assertion errors in simulation output**
3. **Use comprehensive verification scripts**
4. **Test assertions thoroughly before committing**

This prevents false passes and ensures design correctness.
