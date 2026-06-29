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

**必须检查的阻塞性问题：**
- Interface/Modport 使用违规（见下方详细说明）
- 协议违规
- 信号驱动冲突
- 死锁风险

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

### 必须检查的项目（缺一不可）

#### 1. Interface/Modport 使用规范 (Blocking)
**规则：整个验证环境中禁止出现 modport，只能使用 clocking block。**

检查项：
- [ ] Interface 定义中**禁止出现 modport**
- [ ] UVM 类（driver/monitor/sequencer/scoreboard）中**禁止使用 modport**
- [ ] 只能使用 clocking block 访问信号
- [ ] Virtual interface 声明不带 modport：`virtual my_if vif` ✓，`virtual my_if.master vif` ✗
- [ ] 通过 `vif.cb.signal` 访问信号，不是 `vif.modport.signal`

**Why it matters:**
- Clocking block 提供时序同步（input/output skew），modport 不提供
- Clocking block 保证信号采样和驱动在正确的时钟沿，避免竞争
- Modport 仅用于 RTL 模块之间的接口约束，验证环境中不需要

**违规示例：**
```systemverilog
// ❌ 错误：interface 中定义了 modport
interface my_if;
    modport master (...);  // 违规！
endinterface

// ❌ 错误：UVM 类中使用了 modport
class my_driver extends uvm_driver;
    virtual my_if.master vif;  // 违规！
endclass

// ✓ 正确：interface 中只有 clocking block
interface my_if;
    clocking master_cb (...);  // 正确
    clocking monitor_cb (...); // 正确
endinterface

// ✓ 正确：UVM 类中使用 clocking block
class my_driver extends uvm_driver;
    virtual my_if vif;  // 正确
    // 通过 vif.master_cb 访问信号
endclass
```

#### 2. UVC 框架符合性 (Methodology)
检查项：
- [ ] Driver/Monitor 使用 `run()` 方法，不是 `run_phase`
- [ ] VIF 通过 config 对象传递，不是直接声明
- [ ] Analysis port 命名为 `broadcaster`，在 `new()` 中创建
- [ ] Agent 只有 build_phase/connect_phase，无 run_phase（driver/monitor 自管理生命周期）
- [ ] 使用 `extern` 声明分离接口和实现

#### 3. UVM 方法论 (Methodology)
检查项：
- [ ] Factory registration 正确
- [ ] Config_db 使用正确
- [ ] Phase 行为正确
- [ ] Objection 处理正确
- [ ] TLM 连接正确

#### 4. 代码质量 (Maintainability)
检查项：
- [ ] 命名规范一致
- [ ] 注释质量良好
- [ ] 无重复代码
- [ ] 复杂度合理

### 其他检查项

5. Transaction lifecycle safe (copy/clone/randomize)
6. Driver/monitor/sequencer responsibilities separated
7. Scoreboard can observe correct behavior
8. API is usable and stable
9. Verification coverage defined
10. No race conditions or implicit timing assumptions
11. **Assertion verification** (if assertions are present):
    - Assertions use proper timing conditions
    - Assertions are tested and verified to work
    - Verification script checks for assertion errors
    - No false passes due to assertion error reporting
