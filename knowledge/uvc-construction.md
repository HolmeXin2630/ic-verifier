# UVC Construction Guide

## UVC Anatomy

A UVC (UVM Verification Component) is a self-contained, reusable verification unit for a specific protocol or interface.

**Canonical template:** [uvc_gen/templates](https://github.com/HolmeXin2630/uvc_gen/tree/master/templates/default)

## uvc_gen 集成

### 自动生成模板

env-builder skill 集成了 uvc_gen 工具，可以自动生成符合 UVM 规范的代码框架。

**使用方式：**
- 创建新 UVC 时，skill 会自动调用 uvc_gen 生成模板
- 生成的模板包含：agent、driver、monitor、sequencer、transaction 等组件
- 支持 single 和 mstslv 两种模式

**模板定制：**
- 生成的模板可以作为起点进行定制开发
- 遵循模板的代码风格和命名规范
- 可以基于模板进行迭代优化

### 迭代优化

当模板不完全满足需求时，可以使用 Iteration Flow：
1. 分析现有模板结构
2. 识别缺失的组件或功能
3. 参考模板风格进行补全
4. 保持代码一致性

Not every UVC needs all components. Pick what you need based on scope:

| Component | Required? | When to include |
|-----------|-----------|-----------------|
| transaction | Always | Data model for the protocol |
| config | Always | Agent/env behavior configuration |
| driver | Active agent | Drives signals via virtual interface |
| monitor | Always | Observes signals, emits transactions |
| sequencer | Active agent | Arbitrates sequences |
| seq_lib | If has sequences | Stimulus generation library |
| agent | Always | Top-level container for driver/monitor/sequencer |
| environment | Multi-agent | Wraps agents, scoreboard, ref_model |
| environment_cfg | Multi-agent | Agent count, enable flags |
| coverage | If tracking coverage | Functional coverage collector |
| scoreboard | If checking results | Transaction comparison |
| ref_model | If checking results | Reference model for expected data |
| interface | Always | SystemVerilog interface |

### Master/Slave Variant

For protocols with master and slave roles (AXI, AHB), use [uvc_gen_mstslv template](https://github.com/HolmeXin2630/uvc_gen/tree/master/templates/default/xxx_uvc_mstslv) — separate agent/driver/monitor/sequencer per role.

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

### Standard Structure

Reference: [uvc_gen driver template](https://github.com/HolmeXin2630/uvc_gen/blob/master/templates/default/xxx_uvc/xxx_driver.sv)

```systemverilog
class my_driver extends uvm_driver#(my_transaction);
    `uvm_component_utils(my_driver)

    virtual my_if vif;
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
    fork begin
        forever begin
            fork
                begin
                    @(posedge vif.rst_n);
                    vif.reset_driver_signal();  // Reset cleanup in interface
                    get_and_drive();
                end
                begin
                    @(negedge vif.rst_n);
                end
            join_any
            disable fork;
        end
    end join
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

### Key Patterns

- **VIF from config:** `vif = cfg.vif` in `build_phase` — config_db get is done by agent, not driver
- **`run()` not `run_phase`:** Agent calls `run()` from its `run_phase`, allowing per-agent lifecycle control
- **`vif.reset_driver_signal()`:** Reset cleanup logic lives in interface module, not in driver
- **`extern` declarations:** Declare in class body, implement outside — improves readability

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

### Standard Structure

Reference: [uvc_gen monitor template](https://github.com/HolmeXin2630/uvc_gen/blob/master/templates/default/xxx_uvc/xxx_monitor.sv)

```systemverilog
class my_monitor extends uvm_monitor;
    `uvm_component_utils(my_monitor)

    virtual my_if vif;
    my_config cfg;
    uvm_analysis_port#(my_transaction) broadcaster;

    extern function new(string name = "my_monitor", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run();
    extern virtual task rcv_data_phase();
endclass

function my_monitor::new(string name = "my_monitor", uvm_component parent = null);
    super.new(name, parent);
    broadcaster = new("broadcaster", this);  // Created in new(), not build_phase
endfunction

function void my_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    vif = cfg.vif;  // VIF from config
endfunction

// Reset-aware main loop (same pattern as driver)
task my_monitor::run();
    fork begin
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
    end join
endtask

// Protocol-specific monitoring (override per protocol)
task my_monitor::rcv_data_phase();
    fork
        // Protocol-specific collection loop
    join
endtask
```

### Key Patterns

- **`broadcaster` not `ap`:** Analysis port named `broadcaster`, created in `new()`
- **`run()` not `run_phase`:** Same reset-aware pattern as driver
- **`rcv_data_phase()`:** Separate task for protocol-specific monitoring, called after reset deasserts
- **Observable-only:** Monitor never drives signals — purely observational

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

### Multi-UVC Coordination (sqr_pool)

**Do NOT use virtual_sequencer.** Use sqr_pool pattern instead.

See `~/.claude/skills/ic-verifier/knowledge/design-patterns.md` → "Virtual Sequence Pattern (Sequencer Pool)" for full details.

Summary:
1. Agent implements `get_sequencer()` to return its sequencer handle
2. Environment implements `store_sequencers()` to add handles to global sqr_pool
3. Virtual sequence extends `vseq_base` which calls `set_sqr_handles()` to retrieve handles from pool
4. No virtual_sequencer component needed

## Sequence Library

### Base Sequence

```systemverilog
class my_base_sequence extends uvm_sequence#(my_transaction);
    `uvm_object_utils(my_base_sequence)

    function new(string name = "my_base_sequence");
        super.new(name);
    endfunction

    // ✅ DO: Pure stimulus — no objection (parent vseq controls lifecycle)
    virtual task body();
        // ... stimulus ...
    endtask
endclass
```

### Directed Sequence

```systemverilog
class my_directed_sequence extends my_base_sequence;
    `uvm_object_utils(my_directed_sequence)

    // Protocol-specific target fields
    rand bit [31:0] target_addr;
    rand bit [31:0] target_data;

    virtual task body();
        my_transaction item;
        `uvm_do_with(item, {
            item.addr == target_addr;
            item.data == target_data;
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
        // Disable normal constraints for error injection
        item = my_transaction::type_id::create("item");
        item.c_normal.constraint_mode(0);
        // ... randomize with error-specific constraints ...
    endtask
endclass
```

### Typical Sequence Types Per Protocol

| Type | Purpose | Example |
|------|---------|---------|
| Random | Broad coverage | Random addr/data/direction |
| Directed | Targeted tests | Specific register read/write |
| Back-to-back | Timing stress | Zero-delay transactions |
| Error injection | Robustness | Protocol violations, misalignment |
| Burst | Throughput | Multi-beat transfers |
| Reset recovery | Resilience | Traffic after mid-transaction reset |

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

        crs_dir_addr: cross cp_direction, cp_addr_range;
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
3. **Sequencer third** — depends on transaction
4. **Driver fourth** — depends on transaction, config
5. **Monitor fifth** — depends on transaction
6. **Agent sixth** — depends on driver, monitor, sequencer, config
7. **Sequences** — depends on transaction, sequencer
8. **Environment** — depends on agent, config
9. **Coverage, Scoreboard, Ref Model** — depends on transaction
