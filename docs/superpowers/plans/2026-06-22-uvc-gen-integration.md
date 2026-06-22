# UVC Generator 集成实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 uvc_gen 集成到 env-builder skill 中，支持自动生成 UVM 验证组件模板，并支持所有主流 AI coding agents。

**Architecture:** 使用 npx skills 生态系统实现多 agent 支持，通过 install.sh 脚本自动 clone uvc_gen 仓库，在 SKILL.md 中添加 uvc_gen 调用逻辑。

**Tech Stack:** Bash, Markdown, npx skills CLI, Git

## Global Constraints

- 必须支持 npx skills 生态系统（68+ 种 agents）
- uvc_gen 通过 install.sh 自动 clone，不使用 Git submodule
- SKILL.md 使用标准格式，符合 npx skills 规范
- 保持向后兼容，支持现有用户升级

---

### Task 1: 修改 install.sh 支持自动 clone uvc_gen

**Files:**
- Modify: `install.sh`

**Interfaces:**
- Consumes: uvc_gen GitHub 仓库地址 (https://github.com/HolmeXin2630/uvc_gen.git)
- Produces: `tools/uvc_gen/` 目录，包含 uvc_gen.py 和 templates/

- [ ] **Step 1: 备份当前 install.sh**

```bash
cp install.sh install.sh.backup
```

- [ ] **Step 2: 修改 install.sh 添加 uvc_gen 安装逻辑**

在 install.sh 的末尾添加以下代码：

```bash
# 安装 uvc_gen 依赖
UVC_GEN_REPO="https://github.com/HolmeXin2630/uvc_gen.git"
UVC_GEN_BRANCH="main"
UVC_GEN_DIR="$REPO_DIR/tools/uvc_gen"

echo "安装 uvc_gen..."
mkdir -p "$REPO_DIR/tools"

if [ ! -d "$UVC_GEN_DIR" ]; then
    git clone --branch "$UVC_GEN_BRANCH" --depth 1 "$UVC_GEN_REPO" "$UVC_GEN_DIR"
    echo "✅ uvc_gen 已安装到 $UVC_GEN_DIR"
else
    echo "✅ uvc_gen 已存在，跳过安装"
fi

# 检查 Python 依赖
if command -v python3 &> /dev/null; then
    echo "✅ Python3 已安装"
    if [ -f "$UVC_GEN_DIR/requirements.txt" ]; then
        pip3 install -r "$UVC_GEN_DIR/requirements.txt" 2>/dev/null || true
    fi
else
    echo "⚠️  Python3 未安装，uvc_gen 将无法使用"
fi
```

- [ ] **Step 3: 测试 install.sh**

```bash
# 测试安装脚本
bash install.sh

# 验证 uvc_gen 是否安装成功
ls -la ~/.claude/skills/ic-verifier/tools/uvc_gen/
```

- [ ] **Step 4: 提交更改**

```bash
git add install.sh
git commit -m "feat: add uvc_gen auto-installation to install.sh"
```

---

### Task 2: 修改 SKILL.md 添加 uvc_gen 集成逻辑

**Files:**
- Modify: `skills/env-builder/SKILL.md`

**Interfaces:**
- Consumes: `tools/uvc_gen/uvc_gen.py` 脚本
- Produces: 生成的 UVC 模板代码

- [ ] **Step 1: 在 SKILL.md 的 Full Flow 中添加 uvc_gen 检测逻辑**

在 `### Step 2: Requirements Clarification` 之前添加：

```markdown
### Step 1.5: 检测 uvc_gen 可用性

检查 skill 目录下 `tools/uvc_gen/uvc_gen.py` 是否存在：

- **如果存在**：继续下一步
- **如果不存在**：提示用户安装

**提示信息：**
```
uvc_gen 未安装。请运行以下命令安装：

cd <skill目录> && bash install.sh

其中 <skill目录> 可以通过以下方式找到：
- Claude Code: ~/.claude/skills/ic-verifier
- Codex: ~/.codex/skills/ic-verifier
- Cursor: ~/.cursor/skills/ic-verifier

或者使用 npx skills 安装后显示的路径。
```
```

- [ ] **Step 2: 在 Step 1 之后添加参数推断逻辑**

在 `### Step 1: Classify Component Type` 之后添加：

```markdown
### Step 1.2: 推断 uvc_gen 参数

根据用户描述自动推断 uvc_gen 参数：

1. **uvc_name**：从用户描述中提取协议名称（如 AHB、SPI、AXI 等）
2. **mode**：
   - 如果用户提到 "master/slave"、"mstslv"、"主从" 等，使用 mstslv 模式
   - 否则默认使用 single 模式
3. **agent_num**（single 模式）：
   - 如果用户提到 "多个 agent"、"多实例" 等，询问具体数量
   - 否则默认为 1
4. **mst_num/slv_num**（mstslv 模式）：
   - 如果用户指定了数量，使用指定值
   - 否则默认各为 1
5. **可选组件**：
   - 如果用户提到 "coverage"、"覆盖率"，启用 --with-coverage
   - 如果用户提到 "scoreboard"、"记分板"，启用 --with-scoreboard
   - 如果用户提到 "ref_model"、"参考模型"，启用 --with-ref-model
   - 如果用户提到 "env"、"环境"，启用 --with-env
```

- [ ] **Step 3: 在 Step 2 之后添加 uvc_gen 调用逻辑**

在 `### Step 2: Requirements Clarification` 之后添加：

```markdown
### Step 2.5: 生成 UVC 模板

使用 uvc_gen 生成初始模板：

```bash
# 构建命令
python3 tools/uvc_gen/uvc_gen.py \
    -n {uvc_name} \
    -m {mode} \
    -v v1.0 \
    -o {user_project_dir} \
    --agent-num {agent_num} \
    --mst-num {mst_num} \
    --slv-num {slv_num} \
    [--with-coverage] \
    [--with-scoreboard] \
    [--with-ref-model] \
    [--with-env]
```

**参数说明：**
- `{uvc_name}`：协议名称
- `{mode}`：生成模式（single 或 mstslv）
- `{user_project_dir}`：用户当前项目目录
- `{agent_num}`：agent 数量（single 模式）
- `{mst_num}`：master agent 数量（mstslv 模式）
- `{slv_num}`：slave agent 数量（mstslv 模式）

**生成后操作：**
1. 读取生成的模板代码
2. 分析模板结构和代码风格
3. 继续后续的规格说明、计划和实现步骤
```

- [ ] **Step 4: 提交更改**

```bash
git add skills/env-builder/SKILL.md
git commit -m "feat: add uvc_gen integration logic to SKILL.md"
```

---

### Task 3: 添加 Iteration Flow 支持

**Files:**
- Modify: `skills/env-builder/SKILL.md`

**Interfaces:**
- Consumes: 已生成的 UVC 模板代码
- Produces: 迭代优化后的 UVC 代码

- [ ] **Step 1: 在 SKILL.md 中添加 Iteration Flow 定义**

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

- [ ] **Step 2: 在 Flow Classification 部分添加 Iteration Flow**

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

- [ ] **Step 3: 提交更改**

```bash
git add skills/env-builder/SKILL.md
git commit -m "feat: add Iteration Flow for template iteration and completion"
```

---

### Task 4: 更新 README.md 支持 npx skills 安装

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: npx skills CLI
- Produces: 安装说明文档

- [ ] **Step 1: 在 README.md 的 Installation 部分添加 npx skills 安装方式**

修改 `## Installation` 部分：

```markdown
## Installation

### 方式一：使用 npx skills（推荐）

支持 68+ 种 AI coding agents，包括 Claude Code、Codex、Cursor、GitHub Copilot 等。

```bash
npx skills add HolmeXin2630/ic-verifier
```

安装后，运行以下命令安装 uvc_gen 依赖：

```bash
# 找到 skill 目录（根据 agent 类型）
# Claude Code: ~/.claude/skills/ic-verifier
# Codex: ~/.codex/skills/ic-verifier
# Cursor: ~/.cursor/skills/ic-verifier

cd ~/.claude/skills/ic-verifier && bash install.sh
```

### 方式二：手动安装（仅 Claude Code）

```bash
git clone https://github.com/HolmeXin2630/ic-verifier.git
cd ic-verifier
bash install.sh
```

This creates symlinks in `~/.claude/skills/`:
- `ic-verifier/` — shared knowledge (coding standards, review framework)
- `env-builder/` — the UVM environment building skill
```

- [ ] **Step 2: 在 Usage 部分添加多 agent 使用说明**

修改 `## Usage` 部分：

```markdown
## Usage

### 支持的 Agents

本 skill 支持所有主流 AI coding agents，包括：
- Claude Code
- Codex
- Cursor
- GitHub Copilot
- Gemini CLI
- Windsurf
- Cline
- Roo Code
- 等等...

### 首次使用

在你的 AI agent 中运行：

```
> /env-builder
```

The skill will generate `.ic-verifier.yml` in your project root with your simulator and build commands. Confirm or edit the values.
```

- [ ] **Step 3: 提交更改**

```bash
git add README.md
git commit -m "docs: add npx skills installation and multi-agent support"
```

---

### Task 5: 更新知识库文档

**Files:**
- Modify: `knowledge/uvc-construction.md`
- Modify: `knowledge/coding-standards.md`

**Interfaces:**
- Consumes: uvc_gen 生成的模板代码风格
- Produces: 更新后的编码规范和 UVC 构建指南

- [ ] **Step 1: 在 uvc-construction.md 中添加 uvc_gen 集成说明**

在 `## UVC 构建流程` 部分添加：

```markdown
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
```

- [ ] **Step 2: 在 coding-standards.md 中添加 uvc_gen 代码风格说明**

在 `## 命名规范` 部分添加：

```markdown
## uvc_gen 代码风格

uvc_gen 生成的代码遵循以下规范：

### 命名约定
- 类名：`{uvc_name}_{component}` (如 `ahb_driver`)
- 文件名：`{uvc_name}_{component}.sv` (如 `ahb_driver.sv`)
- 接口名：`{uvc_name}_if` (如 `ahb_if`)

### 代码结构
- 使用 UVM 标准宏：`uvm_component_utils`, `uvm_field_utils`
- 遵循 UVM phase 机制
- 使用 config_db 进行配置

### 模板变量
- 使用 `uvc_info` 对象访问 UVC 参数
- 支持模板变量替换
- 保持代码可读性
```

- [ ] **Step 3: 提交更改**

```bash
git add knowledge/uvc-construction.md knowledge/coding-standards.md
git commit -m "docs: add uvc_gen integration and code style guidelines"
```

---

### Task 6: 测试完整流程

**Files:**
- Test: 无新文件，测试现有功能

**Interfaces:**
- Consumes: npx skills CLI, uvc_gen 脚本
- Produces: 测试报告

- [ ] **Step 1: 测试 npx skills 安装**

```bash
# 测试 npx skills 安装
npx skills add HolmeXin2630/ic-verifier

# 验证安装
ls -la ~/.claude/skills/ic-verifier
```

- [ ] **Step 2: 测试 install.sh**

```bash
# 进入 skill 目录
cd ~/.claude/skills/ic-verifier

# 运行 install.sh
bash install.sh

# 验证 uvc_gen 安装
ls -la tools/uvc_gen/uvc_gen.py
```

- [ ] **Step 3: 测试 Full Flow**

在 AI agent 中运行：
```
> /env-builder
> Create an AHB UVC with driver, monitor, and sequencer
```

验证：
1. skill 检测到 uvc_gen 可用
2. 自动推断参数（uvc_name=ahb, mode=single）
3. 调用 uvc_gen 生成模板
4. 继续后续流程

- [ ] **Step 4: 测试 Iteration Flow**

在 AI agent 中运行：
```
> /env-builder
> 模板缺少 scoreboard，需要添加
```

验证：
1. skill 识别为 Iteration Flow
2. 分析现有模板
3. 参考模板风格添加 scoreboard
4. 保持代码一致性

- [ ] **Step 5: 提交测试结果**

```bash
git add -A
git commit -m "test: verify uvc_gen integration and Iteration Flow"
```

---

## 完成检查清单

- [ ] install.sh 支持自动 clone uvc_gen
- [ ] SKILL.md 包含 uvc_gen 检测和调用逻辑
- [ ] SKILL.md 支持 Iteration Flow
- [ ] README.md 包含 npx skills 安装说明
- [ ] 知识库文档更新
- [ ] 完整流程测试通过

## 后续工作

1. 发布到 npx skills 市场
2. 收集用户反馈
3. 优化参数推断逻辑
4. 添加更多协议支持
