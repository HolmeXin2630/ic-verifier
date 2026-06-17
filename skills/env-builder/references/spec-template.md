# [Component Name] Spec

## Overview

One paragraph describing what this component does and why it exists.

## Goals

- [ ] Goal 1
- [ ] Goal 2

## Non-Goals

- Non-goal 1 (and why)
- Non-goal 2

## Public API

### Class Hierarchy

```
uvm_component
└── my_component
    ├── my_sub_component_1
    └── my_sub_component_2
```

### Instantiation

```systemverilog
// Example: how the user creates and configures this component
my_component::type_id::create("inst", this);
```

### Configuration

| Knob | Type | Default | Description |
|------|------|---------|-------------|
| mode | enum | NORMAL | Operating mode |
| depth | int | 16 | FIFO depth |

### TLM Connections

| Port | Type | Direction | Description |
|------|------|-----------|-------------|
| req_port | uvm_blocking_get_port | output | Sends requests |
| rsp_imp | uvm_analysis_imp | input | Receives responses |

## Architecture

Describe the internal structure, data flow, and key design decisions.

## Data Flow

```
sequence → sequencer → driver → DUT
                              ← monitor → analysis_port → scoreboard
```

## UVM Phase Behavior

| Phase | Action |
|-------|--------|
| build_phase | Create sub-components, get config |
| connect_phase | Connect TLM ports |
| run_phase | Main stimulus/response loop |

## Error Handling

| Scenario | Action | Severity |
|----------|--------|----------|
| Protocol violation | Report and continue | uvm_error |
| Timeout | Report and abort | uvm_fatal |
| Config missing | Use default | uvm_warning |

## Verification Strategy

### What to Verify

- [ ] Basic transaction flow
- [ ] Configuration variants
- [ ] Error scenarios
- [ ] Multi-instance behavior
- [ ] Reset handling

### Verification Approach

| Behavior | Method | Level |
|----------|--------|-------|
| Basic flow | Smoke sequence | L2 |
| Config variants | Directed test | L3 |
| Error injection | Constrained random | L4 |

## Open Questions

- Question 1?
- Question 2?
