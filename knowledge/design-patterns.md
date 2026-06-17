# UVM Design Patterns

## Layered Testbench Architecture

### Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│  Layer 3: Test Layer                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Base Test   │  │  Test A      │  │  Test B      │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │             │
│  ┌──────▼────────────────▼────────────────▼──────┐      │
│  │  Virtual Sequencer                             │      │
│  └───────────────────────┬───────────────────────┘      │
├──────────────────────────┼──────────────────────────────┤
│  Layer 2: UVC Layer      │                               │
│  ┌──────────┐  ┌─────────▼────┐  ┌──────────┐          │
│  │ APB UVC  │  │  AXI UVC     │  │ CLK UVC  │          │
│  └──────────┘  └──────────────┘  └──────────┘          │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Interface Layer                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ apb_if   │  │ axi_if   │  │ clk_if   │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
├───────┼──────────────┼──────────────┼───────────────────┤
│  Layer 0: DUT                                             │
│  ┌────▼──────────────▼──────────────▼─────────────────┐ │
│  │              DUT                                    │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Separation of Concerns

| Layer    | Responsibility                        | Examples                     |
|----------|---------------------------------------|------------------------------|
| Test     | Test intent, phase control, factory overrides | `my_test`, `base_test` |
| Env      | UVC instantiation, TLM connection     | `my_env`, `scoreboard`       |
| UVC      | Protocol-specific stimulus/checking   | `apb_agent`, `axi_agent`     |
| Interface| Signal-level abstraction              | `apb_if`, `axi_if`           |

```systemverilog
// ✅ DO: Bind interface in top module, not in class hierarchy
module tb_top;
    // Clock and reset
    logic clk;
    logic rst_n;

    // Interfaces
    apb_if apb_vif(clk, rst_n);
    axi_if axi_vif(clk, rst_n);

    // DUT instantiation
    my_dut dut (
        .pclk    (apb_vif.clk),
        .presetn (apb_vif.rst_n),
        .paddr   (apb_vif.paddr),
        // ...
    );

    // UVM entry point
    initial begin
        // Pass virtual interfaces to UVM
        uvm_config_db#(virtual apb_if)::set(null, "*.agent*", "vif", apb_vif);
        uvm_config_db#(virtual axi_if)::set(null, "*.agent*", "vif", axi_vif);

        run_test();
    end
endmodule
```

## Factory Override Pattern

### Type Override vs Instance Override

```systemverilog
// ✅ DO: Use type override for global substitution
// In test:
virtual function void build_phase(uvm_phase phase);
    // Replace ALL apb_driver instances with slow_driver
    apb_driver::type_id::set_type_override(slow_driver::get_type());
    super.build_phase(phase);
endfunction

// ✅ DO: Use instance override for targeted substitution
virtual function void build_phase(uvm_phase phase);
    // Replace only the agent at this specific path
    apb_driver::type_id::set_inst_override(
        slow_driver::get_type(),
        "env.agent*.drv"
    );
    super.build_phase(phase);
endfunction
```

### Override in Test vs Env

```systemverilog
// ✅ DO: Configure factory in test, not in env
class my_test extends uvm_test;
    `uvm_component_utils(my_test)

    virtual function void build_phase(uvm_phase phase);
        // Test sets factory overrides before env creates components
        set_type_override_by_type(
            my_transaction::get_type(),
            my_extended_transaction::get_type()
        );
        super.build_phase(phase);
    endfunction
endclass

// ❌ DON'T: Set factory overrides in env — it prevents test-level control
class my_env extends uvm_env;
    virtual function void build_phase(uvm_phase phase);
        // WRONG — test can't override this
        set_type_override_by_type(...);
        super.build_phase(phase);
    endfunction
endclass
```

### Override Naming Convention

```systemverilog
// ✅ DO: Use descriptive names for override classes
class slow_apb_driver extends apb_driver;
    // Adds delay between transactions
endclass

class error_injecting_apb_driver extends apb_driver;
    // Injects protocol errors
endclass

class passive_apb_monitor extends apb_monitor;
    // Enhanced checking for passive mode
endclass
```

## Config_db Pattern

### Hierarchical Key Design

```systemverilog
// ✅ DO: Use consistent, hierarchical keys
// Convention: <component_path>.<property_name>
uvm_config_db#(int)::set(this, "agent*", "num_masters", 4);
uvm_config_db#(virtual apb_if)::set(this, "agent*.drv", "vif", vif);

// ✅ DO: Use wildcard in set, explicit path in get
// Parent sets with wildcard (affects all matching children):
uvm_config_db#(int)::set(this, "agent*", "timeout", 1000);

// Child gets with explicit self-reference:
uvm_config_db#(int)::get(this, "", "timeout", timeout);
```

### Race Condition Avoidance

```systemverilog
// ✅ DO: Set in build_phase of parent, get in build_phase of child
class my_env extends uvm_env;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Set before children are created
        uvm_config_db#(int)::set(this, "agent*", "num_masters", 4);
        // Create children
        agent = my_agent::type_id::create("agent", this);
    endfunction
endclass

class my_agent extends uvm_agent;
    int num_masters;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Get after parent has set
        if (!uvm_config_db#(int)::get(this, "", "num_masters", num_masters))
            `uvm_fatal("CFG", "num_masters not set")
    endfunction
endclass
```

### Type-Safe Wrapper Pattern

```systemverilog
// ✅ DO: Create a config wrapper for complex configurations
class my_env_config extends uvm_object;
    int num_masters;
    int num_slaves;
    bit enable_coverage;
    // ... more fields ...

    // Type-safe get/set methods
    static function bit get_config(uvm_component cntxt, output my_env_config cfg);
        return uvm_config_db#(my_env_config)::get(cntxt, "", "env_cfg", cfg);
    endfunction

    static function void set_config(uvm_component cntxt, input my_env_config cfg);
        uvm_config_db#(my_env_config)::set(cntxt, "env*", "env_cfg", cfg);
    endfunction
endclass
```

## TLM Connection Pattern

### Analysis Port Fan-Out

```systemverilog
// ✅ DO: Connect one analysis port to multiple subscribers
virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Monitor emits transactions
    // → Scoreboard checks
    // → Coverage collects
    // → Logger records
    agent.mon.ap.connect(scoreboard.analysis_export);
    agent.mon.ap.connect(coverage.analysis_export);
    agent.mon.ap.connect(logger.analysis_export);
endfunction
```

### TLM Analysis FIFO for Decoupling

```systemverilog
// ✅ DO: Use FIFO when producer and consumer have different rates
class my_scoreboard extends uvm_scoreboard;
    uvm_tlm_analysis_fifo#(my_transaction) expected_fifo;
    uvm_tlm_analysis_fifo#(my_transaction) actual_fifo;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        expected_fifo = new("expected_fifo", this);
        actual_fifo   = new("actual_fifo", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            my_transaction expected, actual;
            expected_fifo.get(expected);
            actual_fifo.get(actual);
            compare(expected, actual);
        end
    endtask
endclass
```

### Request/Response Pattern

```systemverilog
// ✅ DO: Use seq_item_port for request/response with sequencer
class my_driver extends uvm_driver#(my_request, my_response);
    virtual task run_phase(uvm_phase phase);
        forever begin
            my_request req;
            my_response rsp;

            seq_item_port.get_next_item(req);
            drive_and_collect(req, rsp);
            seq_item_port.item_done(rsp);
        end
    endtask
endclass

// In sequence:
virtual task body();
    my_request req;
    my_response rsp;

    `uvm_do(req)
    get_response(rsp);  // Or use `uvm_do_with for inline response handling
endtask
```

## Scoreboard Pattern

### Ordered Comparison

```systemverilog
// ✅ DO: Use FIFO-based scoreboard for ordered protocols (APB, simple AHB)
class ordered_scoreboard extends uvm_scoreboard;
    uvm_tlm_analysis_fifo#(my_transaction) expected_fifo;
    uvm_tlm_analysis_fifo#(my_transaction) actual_fifo;

    int match_count;
    int mismatch_count;

    virtual task run_phase(uvm_phase phase);
        forever begin
            my_transaction exp, act;
            expected_fifo.get(exp);
            actual_fifo.get(act);

            if (!exp.compare(act)) begin
                `uvm_error("SCB", $sformatf(
                    "Mismatch:\n  Expected: %s\n  Actual:   %s",
                    exp.convert2string(), act.convert2string()))
                mismatch_count++;
            end else begin
                `uvm_info("SCB", $sformatf("Match: %s", exp.convert2string()), UVM_HIGH)
                match_count++;
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf(
            "Scoreboard: %0d matches, %0d mismatches",
            match_count, mismatch_count), UVM_LOW)
    endfunction
endclass
```

### Out-of-Order Comparison (Hash-Based)

```systemverilog
// ✅ DO: Use associative array for out-of-order protocols (AXI, PCIe)
class ooo_scoreboard extends uvm_scoreboard;
    // Key: transaction ID
    my_transaction expected_by_id[int unsigned];
    my_transaction actual_by_id[int unsigned];

    virtual function void write_expected(my_transaction t);
        expected_by_id[t.id] = t;
        try_match(t.id);
    endfunction

    virtual function void write_actual(my_transaction t);
        actual_by_id[t.id] = t;
        try_match(t.id);
    endfunction

    virtual function void try_match(int unsigned id);
        if (expected_by_id.exists(id) && actual_by_id.exists(id)) begin
            if (!expected_by_id[id].compare(actual_by_id[id]))
                `uvm_error("SCB", $sformatf("Mismatch for ID %0d", id))
            expected_by_id.delete(id);
            actual_by_id.delete(id);
        end
    endfunction
endclass
```

### End-of-Test Drain

```systemverilog
// ✅ DO: Check for remaining transactions at end of test
virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected_by_id.size() > 0)
        `uvm_error("SCB", $sformatf(
            "%0d expected transactions not received", expected_by_id.size()))
    if (actual_by_id.size() > 0)
        `uvm_error("SCB", $sformatf(
            "%0d unexpected transactions received", actual_by_id.size()))
endfunction
```

## Reset Handling Pattern

### Reset-Aware Driver

```systemverilog
class reset_aware_driver extends uvm_driver#(my_transaction);
    `uvm_component_utils(reset_aware_driver)

    event reset_detected;

    virtual task run_phase(uvm_phase phase);
        forever begin
            fork begin
                fork
                    begin
                        // Main driving loop
                        forever begin
                            my_transaction req;
                            seq_item_port.get_next_item(req);
                            drive_item(req);
                            seq_item_port.item_done();
                        end
                    end
                    begin
                        // Reset detection
                        @(negedge vif.rst_n);
                        -> reset_detected;
                    end
                join_any
                disable fork;
            end join

            // Reset cleanup
            handle_reset();
        end
    endtask

    protected virtual function void handle_reset();
        `uvm_info("DRV", "Reset detected — cleaning up", UVM_MEDIUM)
        reset_signals();
        // Drain any pending items from sequencer
        seq_item_port.disable_auto_item_recording();
        @(posedge vif.rst_n);
        `uvm_info("DRV", "Reset released — resuming", UVM_MEDIUM)
    endfunction

    protected virtual function void reset_signals();
        vif.cb.psel    <= '0;
        vif.cb.penable <= '0;
        vif.cb.paddr   <= '0;
        vif.cb.pwrite  <= '0;
        vif.cb.pwdata  <= '0;
    endfunction
endclass
```

### Reset-Aware Monitor

```systemverilog
class reset_aware_monitor extends uvm_monitor;
    virtual task run_phase(uvm_phase phase);
        forever begin
            my_transaction item;
            fork begin
                fork
                    begin
                        collect_transaction(item);
                        if (item != null) ap.write(item);
                    end
                    begin
                        @(negedge vif.rst_n);
                        item = null;  // Discard incomplete
                    end
                join_any
                disable fork;
            end join

            // Wait for reset release before resuming
            if (!vif.rst_n) begin
                `uvm_info("MON", "Reset — discarding incomplete transaction", UVM_MEDIUM)
                @(posedge vif.rst_n);
            end
        end
    endtask
endclass
```

## Phase Objection Pattern

### Where to Raise/Drop

```systemverilog
// ✅ DO: Raise/drop in sequence (not in driver/monitor)
class my_sequence extends uvm_sequence#(my_transaction);
    virtual task body();
        phase.raise_objection(this, "Starting stimulus");
        `uvm_info("SEQ", "Starting stimulus generation", UVM_MEDIUM)

        // Generate transactions
        repeat (100) begin
            my_transaction item;
            `uvm_do(item)
        end

        `uvm_info("SEQ", "Stimulus complete", UVM_MEDIUM)
        phase.drop_objection(this, "Stimulus complete");
    endtask
endclass

// ❌ DON'T: Raise/drop in driver — driver is a slave
class my_driver extends uvm_driver#(my_transaction);
    virtual task run_phase(uvm_phase phase);
        // WRONG — driver doesn't control test duration
        phase.raise_objection(this);
        // ...
        phase.drop_objection(this);
    endtask
endclass
```

### Timeout Policy

```systemverilog
// ✅ DO: Set reasonable objection timeout in test
class my_test extends uvm_test;
    virtual function void phase_started(uvm_phase phase);
        if (phase.is(uvm_run_phase::get())) begin
            phase.raise_objection(this);
            fork
                begin
                    #10us;  // Test timeout
                    `uvm_fatal("TIMEOUT", "Test timed out")
                end
            join_none
        end
    endfunction
endclass
```

### Drain Time

```systemverilog
// ✅ DO: Allow pending transactions to complete before ending test
class my_test extends uvm_test;
    virtual function void phase_ready_to_end(uvm_phase phase);
        if (phase.is(uvm_run_phase::get())) begin
            // Don't end immediately — wait for scoreboard to drain
            phase.raise_objection(this, "Draining scoreboard");
            fork
                begin
                    #100ns;  // Drain time
                    phase.drop_objection(this, "Drain complete");
                end
            join_none
        end
    endfunction
endclass
```

## Callback Pattern

### Error Injection via Callback

```systemverilog
// ✅ DO: Use uvm_callback for injectable behavior
virtual class my_driver_callback extends uvm_callback;
    `uvm_object_utils(my_driver_callback)

    // Called before driving each transaction
    virtual task pre_drive(my_driver drv, my_transaction item);
        // Default: no-op
    endtask

    // Called after driving each transaction
    virtual task post_drive(my_driver drv, my_transaction item);
        // Default: no-op
    endtask

    // Called to decide if this transaction should be corrupted
    virtual function bit should_corrupt(my_transaction item);
        return 0;  // Default: don't corrupt
    endfunction
endclass

class my_driver extends uvm_driver#(my_transaction);
    `uvm_component_utils(my_driver)

    // Register callback type
    `uvm_register_cb(my_driver, my_driver_callback)

    protected virtual task drive_item(my_transaction item);
        // Call pre_drive callback
        `uvm_do_callbacks(my_driver, my_driver_callback, pre_drive(this, item))

        // Check for corruption
        if (`uvm_do_callbacks(my_driver, my_driver_callback, should_corrupt(item)))
            corrupt_transaction(item);

        // Normal driving
        drive_signals(item);

        // Call post_drive callback
        `uvm_do_callbacks(my_driver, my_driver_callback, post_drive(this, item))
    endtask
endclass

// In test — register callback for error injection
class my_test extends uvm_test;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Register error injection callback
        uvm_callbacks#(my_driver, my_driver_callback)::add(
            env.agent.drv,
            my_error_callback::type_id::create("err_cb")
        );
    endfunction
endclass
```

## Agent Active/Passive Pattern

### Config-Driven Component Creation

```systemverilog
class my_agent extends uvm_agent;
    `uvm_component_utils(my_agent)

    my_config       cfg;
    my_sequencer    sqr;
    my_driver       drv;
    my_monitor      mon;
    my_coverage     cov;

    uvm_analysis_port#(my_transaction) ap;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get configuration
        if (!uvm_config_db#(my_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("NOCFG", "Config not set")

        // Always create monitor
        mon = my_monitor::type_id::create("mon", this);

        // Create active components only if active
        if (cfg.is_active == UVM_ACTIVE) begin
            sqr = my_sequencer::type_id::create("sqr", this);
            drv = my_driver::type_id::create("drv", this);
        end

        // Create coverage if enabled
        if (cfg.has_coverage)
            cov = my_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Analysis port from monitor
        ap = mon.ap;

        // Connect driver to sequencer (active mode only)
        if (cfg.is_active == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);

        // Connect monitor to coverage
        if (cfg.has_coverage)
            mon.ap.connect(cov.analysis_export);
    endfunction
endclass
```

## Virtual Sequence Pattern

### Multi-UVC Coordination

```systemverilog
// ✅ DO: Use virtual sequence for coordinating multiple UVCs
class virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(virtual_sequencer)

    // References to sub-sequencers
    apb_sequencer  apb_sqr;
    axi_sequencer  axi_sqr;
    clk_sequencer  clk_sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

// Base virtual sequence
class base_virtual_sequence extends uvm_sequence;
    `uvm_object_utils(base_virtual_sequence)

    virtual_sequencer v_sqr;

    virtual task body();
        // Override in subclasses
    endtask
endclass

// Example: coordinated traffic
class coordinated_traffic extends base_virtual_sequence;
    `uvm_object_utils(coordinated_traffic)

    virtual task body();
        fork
            // APB configuration writes
            begin
                apb_config_sequence apb_seq;
                `uvm_do_on(apb_seq, v_sqr.apb_sqr)
            end
            // AXI data traffic
            begin
                axi_burst_sequence axi_seq;
                `uvm_do_on(axi_seq, v_sqr.axi_sqr)
            end
        join
    endtask
endclass
```

### Default Sequence on Sequencer

```systemverilog
// ✅ DO: Set default sequence in test
class my_test extends uvm_test;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Set default sequence for APB sequencer
        uvm_config_db#(uvm_object_wrapper)::set(
            this,
            "env.agent.sqr.run_phase",
            "default_sequence",
            apb_random_sequence::get_type()
        );
    endfunction
endclass

// ✅ DO: Use default sequence for simple tests
class my_virtual_test extends my_test;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Set default virtual sequence
        uvm_config_db#(uvm_object_wrapper)::set(
            this,
            "v_sqr.run_phase",
            "default_sequence",
            coordinated_traffic::get_type()
        );
    endfunction
endclass
```
