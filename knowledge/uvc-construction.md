# UVC Construction Guide

## UVC Anatomy

A UVC (UVM Verification Component) is a self-contained, reusable verification unit for a specific protocol or interface. The canonical structure:

```
my_uvc/
├── my_uvc_pkg.sv           ← Package: imports, includes, exports
├── my_transaction.sv        ← Sequence item (data model)
├── my_config.sv             ← Configuration object
├── my_driver.sv             ← Drives signals via virtual interface
├── my_monitor.sv            ← Observes signals, emits transactions
├── my_sequencer.sv          ← Arbitrates sequences
├── my_sequence.sv           ← Stimulus generation library
├── my_agent.sv              ← Top-level container (agent)
├── my_coverage.sv           ← Functional coverage collector
├── my_scoreboard.sv         ← Optional: protocol-level checking
└── my_if.sv                 ← SystemVerilog interface
```

### TLM Topology

```
┌─────────────────────────────────────────┐
│  my_agent (active mode)                 │
│                                         │
│  ┌──────────┐   seq_item_port   ┌───────────┐
│  │  Driver   │◄─────────────────│ Sequencer  │
│  └──────────┘                   └───────────┘
│       │ vif                           ▲
│       │                        sequence │ body()
│       ▼                                 │
│  ┌──────────┐   analysis_port   ┌─────────────┐
│  │  Monitor  │──────────────────►│  Coverage    │
│  └──────────┘        │          └─────────────┘
│                      │
│                      ▼
│               ┌─────────────┐
│               │  Scoreboard  │
│               └─────────────┘
└─────────────────────────────────────────┘
```

### Active vs Passive

| Aspect        | Active Agent                | Passive Agent                |
|---------------|-----------------------------|------------------------------|
| Driver        | Created                     | Not created                  |
| Sequencer     | Created                     | Not created                  |
| Monitor       | Created (always)            | Created (always)             |
| Coverage      | Created (if enabled)        | Created (if enabled)         |
| Use case      | Generating stimulus         | Monitoring/asserting only    |

```systemverilog
// ✅ DO: Use config to control active/passive
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Always create monitor
    mon = my_monitor::type_id::create("mon", this);

    if (cfg.is_active == UVM_ACTIVE) begin
        sqr = my_sequencer::type_id::create("sqr", this);
        drv = my_driver::type_id::create("drv", this);
    end

    if (cfg.has_coverage)
        cov = my_coverage::type_id::create("cov", this);
endfunction
```

## Transaction Design

### uvm_sequence_item

```systemverilog
class my_transaction extends uvm_sequence_item;
    // ── Transaction Fields ──────────────────────────────────
    rand bit [ADDR_WIDTH-1:0] addr;
    rand bit [DATA_WIDTH-1:0] data;
    rand apb_direction_e      direction;
    rand apb_prot_e           prot;

    // ── Response Fields (set by driver/monitor) ────────────
    bit [DATA_WIDTH-1:0]      rdata;    // Response data
    bit                       slverr;   // Slave error

    // ── Metadata (not part of protocol) ────────────────────
    int unsigned              delay;    // Inter-transaction delay

    // ── Factory Registration ───────────────────────────────
    `uvm_object_utils_begin(my_transaction)
        `uvm_field_int(addr,      UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(data,      UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(apb_direction_e, direction, UVM_ALL_ON)
        `uvm_field_enum(apb_prot_e,      prot,      UVM_ALL_ON)
        `uvm_field_int(rdata,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(slverr,    UVM_ALL_ON)
    `uvm_object_utils_end

    // ── Constraints ────────────────────────────────────────
    // Aligned access
    constraint c_aligned {
        addr[1:0] == 2'b00;
    }

    // Reasonable delay range
    constraint c_delay {
        delay inside {[0:10]};
    }

    // ── Methods ────────────────────────────────────────────
    function new(string name = "my_transaction");
        super.new(name);
    endfunction

    // ✅ DO: Implement convert2string for debug output
    virtual function string convert2string();
        return $sformatf("addr=0x%08h data=0x%08h dir=%s prot=%s",
            addr, data, direction.name(), prot.name());
    endfunction

    // ✅ DO: Implement do_compare for scoreboard
    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        my_transaction rhs_cast;
        if (!$cast(rhs_cast, rhs)) return 0;
        return (addr  == rhs_cast.addr) &&
               (data  == rhs_cast.data) &&
               (prot  == rhs_cast.prot);
    endfunction

    // ✅ DO: Implement do_copy for clone operations
    virtual function void do_copy(uvm_object rhs);
        my_transaction rhs_cast;
        super.do_copy(rhs);
        $cast(rhs_cast, rhs);
        addr      = rhs_cast.addr;
        data      = rhs_cast.data;
        direction = rhs_cast.direction;
        prot      = rhs_cast.prot;
        rdata     = rhs_cast.rdata;
        slverr    = rhs_cast.slverr;
        delay     = rhs_cast.delay;
    endfunction
endclass
```

### Field Organization

```
┌─────────────────────────────────────────────┐
│  rand fields     (request: addr, data, ...) │
│  response fields (set by monitor: rdata)    │
│  metadata fields (delay, id, ...)           │
├─────────────────────────────────────────────┤
│  uvm_field macros                           │
├─────────────────────────────────────────────┤
│  constraints     (named blocks: c_aligned)  │
├─────────────────────────────────────────────┤
│  new()                                       │
│  convert2string()                            │
│  do_compare()                                │
│  do_copy()                                   │
│  do_print()                                  │
└─────────────────────────────────────────────┘
```

## Driver Cookbook

### Standard run_phase Loop

```systemverilog
class my_driver extends uvm_driver#(my_transaction);
    `uvm_component_utils(my_driver)

    virtual my_if vif;
    my_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not configured")
        if (!uvm_config_db#(my_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("NOCFG", "Config not set")
    endfunction

    virtual task run_phase(uvm_phase phase);
        // ✅ DO: Wait for reset before starting
        @(posedge vif.rst_n);

        forever begin
            my_transaction req;

            // ✅ DO: Get transaction from sequencer
            seq_item_port.get_next_item(req);

            // ✅ DO: Drive the transaction
            drive_item(req);

            // ✅ DO: Signal completion
            seq_item_port.item_done();
        end
    endtask

    // ✅ DO: Separate driving logic into its own task
    protected virtual task drive_item(my_transaction item);
        `uvm_info("DRV", $sformatf("Driving: %s", item.convert2string()), UVM_HIGH)

        // Setup phase
        vif.cb.psel    <= 1'b1;
        vif.cb.penable <= 1'b0;
        vif.cb.paddr   <= item.addr;
        vif.cb.pwrite  <= (item.direction == APB_WRITE);
        vif.cb.pwdata  <= item.data;
        @(vif.cb);

        // Access phase
        vif.cb.penable <= 1'b1;
        @(vif.cb);

        // Wait for ready
        while (!vif.cb.pready) @(vif.cb);

        // Capture response
        item.rdata  = vif.cb.prdata;
        item.slverr = vif.cb.pslverr;

        // Deassert
        vif.cb.psel    <= 1'b0;
        vif.cb.penable <= 1'b0;
        @(vif.cb);
    endtask
endclass
```

### Reset Handling Pattern

```systemverilog
// ✅ DO: Use fork-join_any for interruptible driving
protected virtual task drive_item(my_transaction item);
    fork begin
        fork
            begin
                // Actual driving
                drive_signals(item);
            end
            begin
                // Wait for reset
                @(negedge vif.rst_n);
            end
        join_any
        disable fork;
    end join

    // If reset occurred, clean up signals
    if (!vif.rst_n) begin
        reset_signals();
        @(posedge vif.rst_n);
    end
endtask

protected virtual function void reset_signals();
    vif.cb.psel    <= '0;
    vif.cb.penable <= '0;
    vif.cb.paddr   <= '0;
    vif.cb.pwrite  <= '0;
    vif.cb.pwdata  <= '0;
endfunction
```

### Back-Pressure Handling

```systemverilog
// ✅ DO: Wait for ready signal in protocol-aware manner
// APB: wait for pready in access phase
// AXI: wait for awready/wready in respective phases

// ❌ DON'T: Use fixed delays for back-pressure
task drive_item(my_transaction item);
    // ...
    #100ns;  // WRONG — doesn't respect protocol
endtask
```

## Monitor Cookbook

### Observable-Only Policy

```systemverilog
class my_monitor extends uvm_monitor;
    `uvm_component_utils(my_monitor)

    virtual my_if vif;
    uvm_analysis_port#(my_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not configured")
    endfunction

    virtual task run_phase(uvm_phase phase);
        // ✅ DO: Monitor is purely observational — never drives signals
        forever begin
            my_transaction item;
            collect_transaction(item);
            if (item != null) begin
                `uvm_info("MON", $sformatf("Observed: %s", item.convert2string()), UVM_HIGH)
                ap.write(item);
            end
        end
    endtask

    // ✅ DO: Extract transaction from signal-level protocol
    protected virtual task collect_transaction(output my_transaction item);
        // Wait for transaction start
        @(posedge vif.clk iff (vif.psel && !vif.penable));

        item = my_transaction::type_id::create("item");
        item.addr = vif.paddr;
        item.direction = vif.pwrite ? APB_WRITE : APB_READ;

        // Wait for access phase
        @(posedge vif.clk iff vif.penable);

        // Wait for completion
        while (!vif.pready) @(posedge vif.clk);

        item.rdata  = vif.prdata;
        item.slverr = vif.pslverr;
    endtask
endclass
```

### Reset Mid-Transaction

```systemverilog
// ✅ DO: Handle reset gracefully in monitor
protected virtual task collect_transaction(output my_transaction item);
    fork begin
        fork
            begin
                // Normal collection
                collect_signals(item);
            end
            begin
                // Reset detection
                @(negedge vif.rst_n);
                item = null;  // Discard incomplete transaction
            end
        join_any
        disable fork;
    end join
endtask
```

## Sequencer Cookbook

### Standard Sequencer

```systemverilog
// ✅ DO: Use parameterized sequencer
class my_sequencer extends uvm_sequencer#(my_transaction);
    `uvm_component_utils(my_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
```

### Lock and Grab

```systemverilog
// ✅ DO: Use lock() for exclusive access with unlock
task body();
    sqr.lock(this);      // Exclusive access until unlock
    // ... generate exclusive traffic ...
    sqr.unlock(this);
endtask

// ✅ DO: Use grab() for immediate exclusive access
task body();
    sqr.grab(this);      // Preempts other sequences
    // ... generate urgent traffic ...
    sqr.ungrab(this);
endtask

// ❌ DON'T: Use lock/grab for normal sequences — they block other traffic
```

### Virtual Sequencer Pattern

```systemverilog
// ✅ DO: Use virtual sequencer for multi-UVC coordination
class virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(virtual_sequencer)

    // References to sub-sequencers
    apb_sequencer  apb_sqr;
    axi_sequencer  axi_sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

// Virtual sequence coordinates multiple UVCs
class my_virtual_sequence extends uvm_sequence;
    `uvm_object_utils(my_virtual_sequence)

    virtual_sequencer v_sqr;

    virtual task body();
        fork
            begin
                // APB traffic
                apb_sequence apb_seq = apb_sequence::type_id::create("apb_seq");
                apb_seq.start(v_sqr.apb_sqr);
            end
            begin
                // AXI traffic
                axi_sequence axi_seq = axi_sequence::type_id::create("axi_seq");
                axi_seq.start(v_sqr.axi_sqr);
            end
        join
    endtask
endclass
```

## Sequence Library

### Base Sequence

```systemverilog
class my_base_sequence extends uvm_sequence#(my_transaction);
    `uvm_object_utils(my_base_sequence)

    function new(string name = "my_base_sequence");
        super.new(name);
    endfunction

    // ✅ DO: Raise/drop objection in body()
    virtual task body();
        phase.raise_objection(this);
        // ... stimulus ...
        phase.drop_objection(this);
    endtask
endclass
```

### Directed Sequence

```systemverilog
class my_directed_sequence extends my_base_sequence;
    `uvm_object_utils(my_directed_sequence)

    rand bit [31:0] target_addr;
    rand bit [31:0] target_data;

    virtual task body();
        my_transaction item;
        `uvm_do_with(item, {
            item.addr == target_addr;
            item.data == target_data;
            item.direction == APB_WRITE;
        })
    endtask
endclass
```

### Random Sequence

```systemverilog
class my_random_sequence extends my_base_sequence;
    `uvm_object_utils(my_random_sequence)

    int unsigned num_transactions = 100;

    virtual task body();
        for (int i = 0; i < num_transactions; i++) begin
            my_transaction item;
            `uvm_do(item)
        end
    endtask
endclass
```

### Error Injection Sequence

```systemverilog
class my_error_sequence extends my_base_sequence;
    `uvm_object_utils(my_error_sequence)

    rand int unsigned error_rate;  // 0-100 percent

    constraint c_error_rate {
        error_rate inside {[10:30]};
    }

    virtual task body();
        my_transaction item;
        forever begin
            `uvm_do_with(item, {
                if (error_rate > $urandom_range(0, 99)) {
                    item.addr[1:0] != 2'b00;  // Misaligned access
                }
            })
        end
    endtask
endclass
```

## Config Object Design

```systemverilog
class my_config extends uvm_object;
    `uvm_object_utils(my_config)

    // ── Agent Behavior ─────────────────────────────────────
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit has_coverage = 1;
    bit has_scoreboard = 1;

    // ── Protocol Parameters ────────────────────────────────
    int unsigned timeout_cycles = 1000;
    bit enable_error_injection = 0;

    // ── Timing ─────────────────────────────────────────────
    int unsigned min_delay = 0;
    int unsigned max_delay = 10;

    function new(string name = "my_config");
        super.new(name);
    endfunction

    // ✅ DO: Provide a convenience method for common config
    static function my_config create_active(string name = "my_config");
        my_config cfg = new(name);
        cfg.is_active = UVM_ACTIVE;
        cfg.has_coverage = 1;
        return cfg;
    endfunction

    static function my_config create_passive(string name = "my_config");
        my_config cfg = new(name);
        cfg.is_active = UVM_PASSIVE;
        cfg.has_coverage = 1;
        return cfg;
    endfunction
endclass
```

### What Goes Where

| Configuration                              | Location              |
|-------------------------------------------|-----------------------|
| Active/passive mode                        | Config object         |
| Number of masters/slaves                   | Config object         |
| Timeout values                             | Config object         |
| Coverage enable/disable                    | Config object         |
| Transaction type                           | Factory override      |
| Driver type                                | Factory override      |
| Virtual interface                          | config_db             |
| Test-specific stimulus constraints         | Sequence (rand vars)  |

## Coverage Integration

### uvm_subscriber Pattern

```systemverilog
class my_coverage extends uvm_subscriber#(my_transaction);
    `uvm_component_utils(my_coverage)

    my_transaction item;

    covergroup cg_apb;
        option.per_instance = 1;

        cp_direction: coverpoint item.direction {
            bins read  = {APB_READ};
            bins write = {APB_WRITE};
        }

        cp_addr_range: coverpoint item.addr[31:12] {
            bins low  = {[0:32'h000F_FFFF]};
            bins mid  = {[32'h0010_0000:32'h00FF_FFFF]};
            bins high = {[32'h0100_0000:32'hFFFF_FFFF]};
        }

        cp_prot: coverpoint item.prot {
            bins normal = {APB_NORMAL};
            bins priv   = {APB_PRIVILEGED};
            bins secure = {APB_SECURE};
        }

        cx_dir_addr: cross cp_direction, cp_addr_range;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_apb = new();
    endfunction

    // ✅ DO: Implement write() to capture transactions
    virtual function void write(my_transaction t);
        item = t;
        cg_apb.sample();
    endfunction
endclass
```

### Connection in Agent

```systemverilog
virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect monitor → coverage
    if (cfg.has_coverage)
        mon.ap.connect(cov.analysis_export);
endfunction
```

## UVC Packaging

### Package File Structure

```systemverilog
package my_uvc_pkg;
    // ── Standard UVM imports ───────────────────────────────
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ── Local imports (if needed) ──────────────────────────
    import my_common_pkg::*;

    // ── Includes (order matters!) ──────────────────────────
    // 1. Transaction (no dependencies)
    `include "my_transaction.sv"

    // 2. Config (no dependencies beyond transaction)
    `include "my_config.sv"

    // 3. Sequences (depend on transaction)
    `include "my_sequence.sv"

    // 4. Driver (depends on transaction, config)
    `include "my_driver.sv"

    // 5. Monitor (depends on transaction)
    `include "my_monitor.sv"

    // 6. Coverage (depends on transaction)
    `include "my_coverage.sv"

    // 7. Sequencer (depends on transaction)
    `include "my_sequencer.sv"

    // 8. Agent (depends on all above)
    `include "my_agent.sv"

endpackage
```

### Parameterized UVC Package

```systemverilog
// ✅ DO: Use package-level parameters for structural configuration
package my_uvc_pkg#(
    int ADDR_WIDTH = 32,
    int DATA_WIDTH = 32
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Use parameters in transaction/agent classes
    typedef class my_transaction;
    typedef class my_agent;

    `include "my_transaction.sv"
    // ...

endpackage
```

### Include Ordering Rules

1. **Transaction first** — no UVM component dependencies
2. **Config second** — may reference transaction types
3. **Sequences third** — depend on transaction
4. **Driver, Monitor, Coverage** — depend on transaction and config
5. **Sequencer** — depends on transaction
6. **Agent last** — depends on all above

### Export Guidelines

```systemverilog
// ✅ DO: Export only what users need
package my_uvc_pkg;
    // Export transaction type
    export my_transaction;

    // Export config type
    export my_config;

    // Export agent type
    export my_agent;

    // Export common sequences
    export my_random_sequence;
    export my_directed_sequence;

    // ❌ DON'T: Export driver, monitor, sequencer internals
    // These are implementation details, not public API
endpackage
```
