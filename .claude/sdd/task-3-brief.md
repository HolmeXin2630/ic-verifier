# Task 3: 添加 Iteration Flow 支持

## 任务描述

在 SKILL.md 中添加 Iteration Flow，支持基于模板迭代优化。

## 文件修改

- Modify: `skills/env-builder/SKILL.md`

## 接口

- Consumes: 已生成的 UVC 模板代码
- Produces: 迭代优化后的 UVC 代码

## 全局约束

- 必须支持 npx skills 生态系统（68+ 种 agents）
- uvc_gen 通过 install.sh 自动 clone，不使用 Git submodule
- SKILL.md 使用标准格式，符合 npx skills 规范
- 保持向后兼容，支持现有用户升级

## 步骤

### Step 1: 在 SKILL.md 中添加 Iteration Flow 定义

在 `## Light Flow` 之前添加：

```markdown
## Iteration Flow

当 uvc_gen 生成的初始模板不完全满足需求时，使用此流程进行迭代优化。

### 适用场景

- 用户反馈"模板缺少 xxx"
- 用户反馈"需要添加 xxx 功能"
- 用户反馈"基于这个模板扩展"

### Step 1: 分析现有模板

读取已生成的 UVC 文件，识别：
- 缺失的组件或功能
- 需要扩展的部分
- 代码风格和命名规范

### Step 2: 制定补全计划

根据分析结果，制定补全计划：
- 参考 uvc_gen 的模板风格
- 保持命名约定一致性
- 遵循 UVM 方法学

### Step 3: 实施补全

基于模板进行补全：
- 补充缺失的组件（如 scoreboard、coverage 等）
- 扩展已有组件的功能
- 保持代码风格一致性

### Step 4: 验证结果

检查补全结果：
- 编译检查
- 基本功能测试
- 代码风格审查

### Step 5: 交付

将补全后的代码交付给用户，并说明修改内容。
```

### Step 2: 在 Flow Classification 部分添加 Iteration Flow

修改 `## Flow Classification` 部分：

```markdown
## Flow Classification

Determine which flow to use based on the user's request:

### Full Flow — New component, major refactoring
Triggers: "create", "build", "new UVC", "new component", "reusable package", "from scratch"

### Iteration Flow — Template iteration and completion
Triggers: "模板缺少", "需要添加", "基于模板扩展", "template missing", "add to template", "extend template"

### Light Flow — Small modification, feature addition, bug fix
Triggers: "add", "fix", "modify", "update", "change", "enhance", "extend"

### Review-Only Flow — Code review without modification
Triggers: "review", "check", "audit", "look at", "evaluate"

When ambiguous, ask: "Is this a new component, a modification, a template iteration, or a review?"
```

### Step 3: 提交更改

```bash
git add skills/env-builder/SKILL.md
git commit -m "feat: add Iteration Flow for template iteration and completion"
```
