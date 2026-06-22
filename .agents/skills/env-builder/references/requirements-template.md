# Requirements Clarification Template

## General Questions (All Components)

1. What is the target component type? (UVC / agent / driver / monitor / sequencer / sequence library / scoreboard / subscriber / coverage collector / SV package / utility library)
2. What protocol or interface does it work with?
3. What transaction type does it use? Does one exist or need to be created?
4. What is the intended usage context? (standalone testbench / SoC environment / reusable library)
5. Does it need to support multiple instances or channels?

## API and Configuration

6. What is the public API? How does the user instantiate and connect this component?
7. What configuration knobs are needed? (timing modes, error injection, verbosity, etc.)
8. Does it need factory override support?
9. Does it need callback or extension points?

## Behavior

10. What phases does it operate in? (build_phase / connect_phase / run_phase / etc.)
11. What TLM ports does it need? (analysis port, request/response port, etc.)
12. How does it report errors? (uvm_error / uvm_fatal / custom reporting)
13. What are the key behaviors that must be verified?

## Reuse and Constraints

14. Is this a one-off component or intended for reuse across projects?
15. Does it need parameterization? (bus width, FIFO depth, etc.)
16. Are there existing base classes or packages it should extend?
17. What are the dependencies? (interface, other UVM components, SV packages)

## Verification

18. What is the verification completion criteria?
19. Is a simulation environment available?
20. What simulator is used? (VCS / Xcelium / Questa)

---

## Component-Specific Questions

### UVC / VIP
- Does it need a built-in scoreboard?
- Does it need coverage collection?
- What error scenarios must be handled?
- Does it support backdoor access?

### Driver
- What is the signal-level protocol?
- Does it support multiple driving modes?
- How does it handle reset?
- What is the timing relationship between request and response?

### Monitor
- What transactions does it observe and extract?
- Does it need protocol checking?
- Does it emit analysis transactions?
- How does it handle protocol violations?

### Scoreboard
- What is the comparison strategy? (exact / statistical / tolerance)
- How are out-of-order transactions handled?
- What is the match/mismatch reporting format?
- Does it need a reference model?

### Sequence Library
- What scenarios must be covered?
- What constraints define valid vs. invalid transactions?
- Does it need directed sequences?
- Does it support virtual sequences?

### SV Package / Utility Library
- What is the API surface?
- Does it need backward compatibility?
- What are the performance requirements?
- How is it tested without UVM?
