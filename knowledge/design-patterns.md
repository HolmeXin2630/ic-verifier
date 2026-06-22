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
│  │  sqr_pool (global singleton)                   │      │
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

### Rule: config_db Only for Virtual Interface (module → UVM)

```systemverilog
// ✅ DO: Use config_db ONLY for passing VIF from module domain to UVM domain
// In tb_top (module domain):
initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*.apb_agnt*", "vif", apb_vif);
    uvm_config_db#(virtual axi_if)::set(null, "*.axi_agnt*", "vif", axi_vif);
    run_test();
end

// In agent (UVM domain):
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "VIF not set")
endfunction

// ❌ DON'T: Use config_db to pass config/parameters within UVM hierarchy
// UVM components should use explicit dependency injection instead
```

### Dependency Injection Within UVM Hierarchy

Reference: [uvc_gen environment template](https://github.com/HolmeXin2630/uvc_gen/blob/master/templates/default/xxx_uvc/xxx_environment.sv)

```systemverilog
// ✅ DO: env_cfg holds agt_cfg[], env injects into agents
class my_env_cfg extends uvm_object;
    `uvm_object_utils(my_env_cfg)

    int agent_num = 2;
    my_agent_cfg agt_cfg[];  // Array of agent configs

    function new(string name = "my_env_cfg");
        super.new(name);
    endfunction

    function void build();
        agt_cfg = new[agent_num];
        foreach (agt_cfg[i])
            agt_cfg[i] = my_agent_cfg::type_id::create($sformatf("agt_cfg[%0d]", i));
    endfunction
endclass

class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    my_env_cfg  env_cfg;
    my_agent    agt[];

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Build agent configs from env_cfg
        env_cfg.build();

        // Create agents and inject configs
        agt = new[env_cfg.agent_num];
        foreach (agt[i]) begin
            agt[i] = my_agent::type_id::create($sformatf("agt[%0d]", i), this);
            agt[i].cfg = env_cfg.agt_cfg[i];  // ✅ Direct injection
        end
    endfunction
endclass

// Agent receives config via direct assignment
class my_agent extends uvm_agent;
    my_agent_cfg cfg;  // Set by parent

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // cfg is already set by parent — no config_db get needed
        if (cfg == null)
            `uvm_fatal("NOCFG", "Config not injected by parent")
    endfunction
endclass
```

### Why

| Aspect | config_db | Dependency Injection |
|--------|-----------|---------------------|
| Type safety | Runtime check | Compile-time check |
| Traceability | Hidden, string-keyed | Explicit, visible in code |
| Refactoring | Fragile (path changes break it) | Safe (compiler catches errors) |
| Debug | Hard (dump config_db) | Easy (follow assignments) |
| Use case | module→UVM boundary only | UVM hierarchy |

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

**Pattern:** Use `run()` task (not `run_phase`) with `forever begin...end` loop. Reset detection uses `fork...join_any` with `disable fork`. Signal cleanup lives in interface's `reset_driver_signal()` task.

```systemverilog
class my_driver extends uvm_driver#(my_transaction);
    `uvm_component_utils(my_driver)

    virtual interface my_if vif;
    my_config cfg;

    extern function new(string name = "my_driver", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual protected task get_and_drive();
    extern virtual protected task drive_trans(my_transaction trans);
    extern virtual task run();
endclass

function my_driver::new(string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction

function void my_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    vif = cfg.vif;  // VIF from config, not config_db
endfunction

// Reset-aware main loop
task my_driver::run();
    fork begin  // Guard fork
        forever begin
            fork
                begin
                    @(posedge vif.mrst_n);
                    vif.reset_driver_signal();  // Reset cleanup in interface
                    get_and_drive();
                end
                begin
                    @(negedge vif.mrst_n);
                end
            join_any
            disable fork;
        end
    end join  // Guard fork
endtask

// Standard get_next_item loop
task my_driver::get_and_drive();
    forever begin
        seq_item_port.get_next_item(req);
        drive_trans(req);
        seq_item_port.item_done();
    end
endtask

// Protocol-specific driving (override per protocol)
task my_driver::drive_trans(my_transaction trans);
    // Protocol-specific implementation
endtask
```

**Key Points:**
- **`run()` not `run_phase`:** Agent calls `run()` from its `run_phase`, allowing per-agent lifecycle control
- **`vif.mrst_n`:** Active-low reset signal, named `mrst_n` in interface
- **`vif.reset_driver_signal()`:** Reset cleanup logic lives in interface module, not in driver
- **`forever begin...end` loop:** Continuously detects reset and restarts driving
- **`fork...join_any` + `disable fork`:** Interrupts driving when reset detected

### Reset-Aware Monitor

**Pattern:** Use `run()` task (not `run_phase`) with same reset-aware pattern as driver. Protocol-specific monitoring in separate `rcv_data_phase()` task.

```systemverilog
class my_monitor extends uvm_monitor;
    `uvm_component_utils(my_monitor)

    virtual interface my_if vif;
    my_config cfg;

    uvm_analysis_port#(my_transaction) broadcaster;

    extern function new(string name = "my_monitor", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run();
    extern virtual task rcv_data_phase();
endclass

function my_monitor::new(string name = "my_monitor", uvm_component parent = null);
    super.new(name, parent);
    broadcaster = new("broadcaster", this);
endfunction

function void my_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    vif = cfg.vif;  // VIF from config, not config_db
endfunction

// Reset-aware main loop
task my_monitor::run();
    fork begin  // Guard fork
        forever begin
            fork
                begin
                    @(posedge vif.mrst_n);
                    rcv_data_phase();
                end
                begin
                    @(negedge vif.mrst_n);
                end
            join_any
            disable fork;
        end
    end join  // Guard fork
endtask

// Protocol-specific monitoring (override per protocol)
task my_monitor::rcv_data_phase();
    fork
        // Protocol-specific collection loop
    join
endtask
```

**Key Points:**
- **`broadcaster` not `ap`:** Analysis port named `broadcaster`, created in `new()`
- **`run()` not `run_phase`:** Same reset-aware pattern as driver
- **`rcv_data_phase()`:** Separate task for protocol-specific monitoring, called after reset deasserts
- **Observable-only:** Monitor never drives signals — purely observational

## Phase Objection Pattern

### Where to Raise/Drop

```systemverilog
// ✅ DO: Raise/drop ONLY in top-level virtual sequence
class my_virtual_sequence extends uvm_sequence;
    virtual task body();
        phase.raise_objection(this, "Test start");
        `uvm_info("VSEQ", "Starting coordinated stimulus", UVM_MEDIUM)

        fork
            apb_seq.start(apb_sqr);
            axi_seq.start(axi_sqr);
        join

        `uvm_info("VSEQ", "Stimulus complete", UVM_MEDIUM)
        phase.drop_objection(this, "Test end");
    endtask
endclass

// ❌ DON'T: Raise/drop in UVC sub-sequences — they are pure stimulus generators
class apb_sequence extends uvm_sequence#(apb_transaction);
    virtual task body();
        // NO objection — parent vseq controls lifecycle
        repeat (100) begin
            my_transaction item;
            `uvm_do(item)
        end
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

    // ✅ DO: Provide get_sequencer() for sqr_pool integration
    virtual function uvm_sequencer_base get_sequencer();
        return sqr;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Config injected by parent — verify it exists
        if (cfg == null)
            `uvm_fatal("NOCFG", "Config not injected by parent")

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

## Virtual Sequence Pattern (Sequencer Pool)

Reference: [DVCon India 2025 — Cummings, Glasser, Kulkarni](https://dvcon-proceedings.org/wp-content/uploads/1B1-DVConIndia2025_Final_Paper_3272.pdf)

**Do NOT use virtual_sequencer.** Use sqr_pool (singleton) or sqr_aggregator instead.

### sqr_pool — Global Sequencer Pool

```systemverilog
// String-keyed singleton pool for sequencer handles
class sqr_pool #(type T = uvm_sequencer_base) extends uvm_object;
    static sqr_pool#(T) pool;
    T pool_h[string];

    static function sqr_pool#(T) get_global_pool();
        if (pool == null) pool = new("global_sqr_pool");
        return pool;
    endfunction

    function void add(string name, T sqr);
        pool_h[name] = sqr;
    endfunction

    function T get(string name);
        if (!pool_h.exists(name))
            `uvm_fatal("SQR_POOL", $sformatf("Sequencer '%0s' not found", name))
        return pool_h[name];
    endfunction

    function void dump();
        `uvm_info("SQR_POOL", "--- SEQUENCER POOL ENTRIES ---", UVM_LOW)
        foreach (pool_h[name])
            `uvm_info("SQR_POOL", $sformatf("%10s : %s", name, pool_h[name].get_full_name()), UVM_LOW)
        `uvm_info("SQR_POOL", "--- END SEQUENCER POOL ---", UVM_LOW)
    endfunction
endclass
```

### Agent: get_sequencer()

```systemverilog
// ✅ DO: Every agent implements get_sequencer()
class my_agent extends uvm_agent;
    my_sequencer sqr;

    virtual function uvm_sequencer_base get_sequencer();
        return sqr;
    endfunction
endclass
```

### Environment: store_sequencers()

```systemverilog
// ✅ DO: Environment stores agent sequencers into pool
class my_env extends uvm_env;
    typedef sqr_pool#(uvm_sequencer_base) sqr_pool_type;
    sqr_pool_type sqrs = sqr_pool_type::get_global_pool();

    apb_agent apb_agnt;
    axi_agent axi_agnt;

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        store_sequencers();
    endfunction

    virtual function void store_sequencers();
        sqrs.add("APB", apb_agnt.get_sequencer());
        sqrs.add("AXI", axi_agnt.get_sequencer());
    endfunction
endclass
```

### Virtual Sequence: set_sqr_handles()

```systemverilog
// ✅ DO: vseq_base retrieves handles from pool
class vseq_base extends uvm_sequence#(uvm_sequence_item);
    `uvm_object_utils(vseq_base)

    typedef sqr_pool#(uvm_sequencer_base) sqr_pool_type;
    sqr_pool_type sqrs = sqr_pool_type::get_global_pool();

    uvm_sequencer_base APB;
    uvm_sequencer_base AXI;

    virtual function void set_sqr_handles();
        if (APB == null) begin
            APB = sqrs.get("APB");
            AXI = sqrs.get("AXI");
        end
    endfunction
endclass

// Concrete virtual sequence
class my_vseq extends vseq_base;
    `uvm_object_utils(my_vseq)

    task body();
        apb_sequence apb_seq = apb_sequence::type_id::create("apb_seq");
        axi_sequence axi_seq = axi_sequence::type_id::create("axi_seq");

        set_sqr_handles();

        fork
            apb_seq.start(APB);
            axi_seq.start(AXI);
        join
    endtask
endclass
```

### Test: dump() for Debug

```systemverilog
// ✅ DO: Call dump() in start_of_simulation_phase to verify pool contents
class my_test extends uvm_test;
    typedef sqr_pool#(uvm_sequencer_base) sqr_pool_type;
    sqr_pool_type sqrs = sqr_pool_type::get_global_pool();

    virtual function void start_of_simulation_phase(uvm_phase phase);
        sqrs.dump();
    endfunction
endclass
```

### Why sqr_pool Over Virtual Sequencer

| Aspect              | virtual_sequencer          | sqr_pool                     |
|---------------------|----------------------------|------------------------------|
| Coupling            | Tight — vseq must know sqr paths | Loose — string-keyed lookup |
| Reusability         | Poor — vseq tied to env hierarchy | High — any env can add to pool |
| Multi-env           | Need multiple vsequencers  | Single pool, unique names    |
| Agent awareness     | Agent unaware              | Agent unaware (just get_sequencer) |
| Debug               | Hard to trace              | dump() shows all entries     |
