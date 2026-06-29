# Review-Only Flow

For reviewing existing code without modification.

**Triggers:** "review", "check", "audit", "evaluate"

## Step 1: Read

Read target files and any available spec/documentation.

## Step 2: Review

Read these knowledge files as needed:
- `knowledge/review-framework.md` — verdict format and finding categories
- `knowledge/coding-standards.md` — naming, style, **interface/modport rules**
- `knowledge/uvc-construction.md` — UVC/agent/driver/monitor patterns
- `knowledge/design-patterns.md` — factory, config_db, TLM, reset

Review against: UVM methodology, coding standards, API design, verification completeness.

### Mandatory Checklist

**必须检查以下所有项目，缺一不可：**

#### 1. Interface/Modport 使用规范 (coding-standards.md)
- [ ] **整个验证环境中禁止出现 modport**
- [ ] Interface 定义中**禁止声明 modport**
- [ ] UVM 类（driver/monitor/sequencer/scoreboard）中**禁止使用 modport**
- [ ] 只能使用 clocking block 访问信号
- [ ] Virtual interface 声明不带 modport：`virtual my_if vif` ✓，`virtual my_if.master vif` ✗
- [ ] 通过 `vif.cb.signal` 访问信号，不是 `vif.modport.signal`

#### 2. UVC 框架符合性 (uvc-construction.md)
- [ ] Driver/Monitor 使用 `run()` 方法，不是 `run_phase`
- [ ] VIF 通过 config 对象传递，不是直接声明
- [ ] Analysis port 命名为 `broadcaster`，在 `new()` 中创建
- [ ] Agent 只有 build_phase/connect_phase，无 run_phase（driver/monitor 自管理生命周期）
- [ ] 使用 `extern` 声明分离接口和实现

#### 3. UVM 方法论 (review-framework.md)
- [ ] Factory registration 正确
- [ ] Config_db 使用正确
- [ ] Phase 行为正确
- [ ] Objection 处理正确
- [ ] TLM 连接正确

#### 4. 代码质量 (coding-standards.md)
- [ ] 命名规范一致
- [ ] 注释质量良好
- [ ] 无重复代码
- [ ] 复杂度合理

Output: Verdict (pass/pass-with-nits/changes-required/blocked) + findings per category.

## Step 3: Report

Present findings. Do NOT modify code unless explicitly asked.
