# UVC Generator 集成设计文档

**日期：** 2026-06-22
**状态：** 已批准
**作者：** Claude Code

## 1. 概述

### 1.1 目标

优化 env-builder skill，使其能够：
1. 自动调用 uvc_gen 生成 UVM 验证组件模板
2. 基于生成的模板进行定制开发
3. 支持所有主流 AI coding agents（68+ 种）

### 1.2 背景

当前 env-builder skill 要求用户手动创建 UVC 代码框架，效率低且容易出错。uvc_gen 是一个成熟的代码生成工具，可以自动生成符合 UVM 规范的代码框架。

### 1.3 关键决策

| 决策 | 选择 | 理由 |
|------|------|------|
| uvc_gen 集成方式 | install.sh 自动 clone | 安装简单，维护独立 |
| 多 agent 支持 | npx skills 生态系统 | 一次性支持 68+ 种 agents |
| Skill 格式 | SKILL.md（通用格式） | npx skills 标准格式 |

## 2. 架构设计

### 2.1 整体架构

```
用户安装
    ↓
npx skills add HolmeXin2630/ic-verifier
    ↓
自动创建 symlink 到各 agent 目录
    ↓
用户运行 install.sh（可选）
    ↓
自动 clone uvc_gen 到 tools/ 目录
```

### 2.2 文件结构

**仓库结构（GitHub）：**
```
ic-verifier/
├── skills/
│   └── env-builder/
│       └── SKILL.md              # Skill 定义（通用格式）
├── knowledge/
│   ├── coding-standards.md
│   ├── uvc-construction.md
│   ├── design-patterns.md
│   ├── review-framework.md
│   └── assertion-verification.md
├── tools/
│   └── README.md                 # 说明如何安装 uvc_gen
├── install.sh                    # 自动安装脚本
├── README.md
└── LICENSE
```

**安装后结构（用户机器）：**
```
~/.claude/skills/ic-verifier/     # 或其他 agent 目录
├── skills/
│   └── env-builder/
│       └── SKILL.md
├── knowledge/
├── tools/
│   └── uvc_gen/                  # install.sh 自动 clone
│       ├── uvc_gen.py
│       └── templates/
└── install.sh
```

### 2.3 安装流程

#### 步骤一：安装 skill

```bash
npx skills add HolmeXin2630/ic-verifier
```

- 自动创建 symlink 到各 agent 目录
- skill 可以正常使用

#### 步骤二：安装 uvc_gen（首次使用时提示）

**自动检测机制：**
- skill 运行时检测 `tools/uvc_gen/uvc_gen.py` 是否存在
- 如果不存在：提示用户运行安装命令
- 如果存在：直接调用 uvc_gen 生成模板

**用户安装 uvc_gen：**
```bash
# 自动检测 skill 目录（支持所有 agent）
SKILL_DIR=$(find ~/.claude/skills ~/.codex/skills ~/.cursor/skills ~/.copilot/skills \
    -name "ic-verifier" -type d 2>/dev/null | head -1)

# 运行安装脚本
cd "$SKILL_DIR" && bash install.sh
```

**或者使用 npx skills 提供的路径：**
```bash
# npx skills 安装后会显示路径
npx skills add HolmeXin2630/ic-verifier
# 输出：Installed to ~/.claude/skills/ic-verifier

# 直接使用显示的路径
cd ~/.claude/skills/ic-verifier && bash install.sh
```

**为什么采用这种方式？**
- npx skills 不支持 post-install hook
- 用户无需提前知道 uvc_gen 的存在
- 首次使用时友好提示，用户体验好
- 自动检测支持所有 agent 类型

## 3. Skill 工作流程

### 3.1 流程分类

| 流程 | 触发条件 | 是否调用 uvc_gen |
|------|---------|-----------------|
| Full Flow | 创建新 UVC/组件 | ✅ 是 |
| Iteration Flow | 基于模板迭代优化 | ❌ 否（基于已有模板） |
| Light Flow | 修改现有代码 | ❌ 否 |
| Review-Only Flow | 代码审查 | ❌ 否 |

### 3.2 Full Flow（集成 uvc_gen）

```
1. 用户请求创建新 UVC
   ↓
2. 识别组件类型（UVC/agent/driver/monitor 等）
   ↓
3. 自动推断 uvc_gen 参数
   - uvc_name：从用户描述提取
   - mode：根据 "master/slave" 关键词判断
   - agent_num/mst_num/slv_num：根据描述推断
   - 可选组件：根据关键词启用
   ↓
4. 检测 uvc_gen 是否可用
   - 检查 skill 目录下 tools/uvc_gen/uvc_gen.py 是否存在
   ├─ 存在 → 继续步骤 5
   └─ 不存在 → 提示用户：
       "uvc_gen 未安装。运行以下命令安装："
       "cd <skill目录> && bash install.sh"
       其中 <skill目录> 根据 agent 类型自动检测
       等待用户安装后继续
   ↓
5. 调用 uvc_gen 生成模板到用户项目目录
   ↓
6. 读取生成的模板代码
   ↓
7. 继后续的规格说明、计划和实现步骤
   ↓
8. 基于模板代码进行定制开发
```

### 3.3 迭代模式（基于模板补全）

当 uvc_gen 生成的初始模板不完全满足需求时，支持基于模板进行迭代优化：

```
1. 用户反馈模板不满足需求
   ↓
2. 分析现有模板结构
   - 读取已生成的 UVC 文件
   - 识别缺失的组件或功能
   ↓
3. 根据模板补全
   - 参考 uvc_gen 的模板风格和命名规范
   - 补充缺失的组件（如 scoreboard、coverage 等）
   - 扩展已有组件的功能
   ↓
4. 保持一致性
   - 遵循模板的代码风格
   - 使用相同的命名约定
   - 保持 UVM 方法学正确性
   ↓
5. 验证补全结果
   - 检查编译
   - 运行基本测试
```

**触发条件：**
- 用户说"模板缺少 xxx"
- 用户说"需要添加 xxx 功能"
- 用户说"基于这个模板扩展"

**补全策略：**
| 场景 | 处理方式 |
|------|---------|
| 缺少可选组件 | 参考模板中的可选组件模板补全 |
| 需要扩展功能 | 基于模板风格编写新代码 |
| 需要修改结构 | 重构时保持模板的命名和风格 |

### 3.4 参数推断逻辑

```python
def infer_uvc_gen_params(user_description):
    """从用户描述推断 uvc_gen 参数"""

    # 1. uvc_name
    uvc_name = extract_protocol_name(user_description)
    # 示例：AHB、SPI、AXI、I2C 等

    # 2. mode
    if any(keyword in user_description for keyword in
           ['master/slave', 'mstslv', '主从', 'mst_slv']):
        mode = 'mstslv'
    else:
        mode = 'single'

    # 3. agent_num (single 模式)
    if any(keyword in user_description for keyword in
           ['多个 agent', '多实例', 'multiple agents']):
        agent_num = ask_user_for_number()
    else:
        agent_num = 1

    # 4. mst_num/slv_num (mstslv 模式)
    mst_num = extract_number(user_description, 'master') or 1
    slv_num = extract_number(user_description, 'slave') or 1

    # 5. 可选组件
    with_coverage = 'coverage' in user_description or '覆盖率' in user_description
    with_scoreboard = 'scoreboard' in user_description or '记分板' in user_description
    with_ref_model = 'ref_model' in user_description or '参考模型' in user_description
    with_env = 'env' in user_description or '环境' in user_description

    return {
        'uvc_name': uvc_name,
        'mode': mode,
        'agent_num': agent_num,
        'mst_num': mst_num,
        'slv_num': slv_num,
        'with_coverage': with_coverage,
        'with_scoreboard': with_scoreboard,
        'with_ref_model': with_ref_model,
        'with_env': with_env
    }
```

### 3.4 uvc_gen 调用方式

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

## 4. install.sh 设计

```bash
#!/bin/bash
# IC Verifier 安装脚本
# 自动安装 uvc_gen 依赖

set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
UVC_GEN_REPO="https://github.com/HolmeXin2630/uvc_gen.git"
UVC_GEN_BRANCH="main"
UVC_GEN_DIR="$SKILL_DIR/tools/uvc_gen"

echo "=== IC Verifier 安装脚本 ==="

# 创建 tools 目录
mkdir -p "$SKILL_DIR/tools"

# 安装 uvc_gen
if [ ! -d "$UVC_GEN_DIR" ]; then
    echo "正在安装 uvc_gen..."
    git clone --branch "$UVC_GEN_BRANCH" --depth 1 "$UVC_GEN_REPO" "$UVC_GEN_DIR"
    echo "✅ uvc_gen 已安装到 $UVC_GEN_DIR"
else
    echo "✅ uvc_gen 已存在，跳过安装"
fi

# 检查 Python 依赖
echo "检查 Python 依赖..."
if command -v python3 &> /dev/null; then
    echo "✅ Python3 已安装"
    # 安装 uvc_gen 依赖（如果需要）
    if [ -f "$UVC_GEN_DIR/requirements.txt" ]; then
        pip3 install -r "$UVC_GEN_DIR/requirements.txt" 2>/dev/null || true
    fi
else
    echo "⚠️  Python3 未安装，uvc_gen 将无法使用"
fi

echo ""
echo "=== 安装完成 ==="
echo "使用方式："
echo "  1. 在你的 AI agent 中运行 /env-builder"
echo "  2. 请求创建新 UVC，例如：'Create an AHB UVC'"
echo ""
echo "支持的 agents：Claude Code, Codex, Cursor, GitHub Copilot, Gemini CLI 等 68+ 种"
```

## 5. 多 Agent 支持

### 5.1 npx skills 生态系统

使用 Vercel Labs 的 `npx skills` 工具，一次性支持 68+ 种 agents：

```bash
# 安装命令
npx skills add HolmeXin2630/ic-verifier

# 自动支持的 agents
- Claude Code
- Codex
- Cursor
- GitHub Copilot
- Gemini CLI
- Windsurf
- Cline
- Roo Code
- 等等...
```

### 5.2 目录映射

| Agent | 项目路径 | 全局路径 |
|-------|---------|---------|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.agents/skills/` | `~/.codex/skills/` |
| Cursor | `.agents/skills/` | `~/.cursor/skills/` |
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` |
| Gemini CLI | `.agents/skills/` | `~/.gemini/skills/` |
| Windsurf | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |

### 5.3 Skill 格式

使用标准的 SKILL.md 格式：

```markdown
---
name: env-builder
description: "Use when creating, modifying, testing, or reviewing SystemVerilog libraries, UVM components, UVCs, VIP, or reusable IC verification infrastructure."
---

# UVM Environment Builder

具体内容...
```

## 6. 迁移计划

### 6.1 从当前格式迁移到 npx skills 格式

1. **保持目录结构**
   - skills/env-builder/SKILL.md（已符合格式）
   - knowledge/（共享知识库）

2. **添加 npx skills 支持**
   - 确保 SKILL.md 的 frontmatter 符合规范
   - 测试 `npx skills add` 安装

3. **修改 install.sh**
   - 添加自动 clone uvc_gen 逻辑
   - 添加依赖检查

4. **更新 README.md**
   - 添加 npx skills 安装说明
   - 添加 uvc_gen 集成说明

### 6.2 测试计划

| 测试项 | 验证方式 |
|--------|---------|
| npx skills 安装 | `npx skills add HolmeXin2630/ic-verifier` |
| Claude Code 加载 | 运行 `/env-builder` |
| uvc_gen 调用 | 创建新 UVC，验证模板生成 |
| 多 agent 支持 | 在 Cursor/Codex 中测试 |

## 7. 后续扩展

### 7.1 可选增强

- [ ] 支持自定义 uvc_gen 模板
- [ ] 支持 uvc_gen 参数配置文件
- [ ] 添加更多协议的知识库
- [ ] 支持 scoreboard/ref_model 自动生成

### 7.2 版本管理

- Skill 版本：通过 Git tag 管理
- uvc_gen 版本：通过 install.sh 参数指定（如 `--branch v1.0`）

## 8. 附录

### 8.1 相关链接

- uvc_gen 仓库：https://github.com/HolmeXin2630/uvc_gen
- npx skills 文档：https://github.com/vercel-labs/skills
- skills.sh 市场：https://skills.sh/

### 8.2 参考资料

- Vercel Labs skills 仓库：https://github.com/vercel-labs/skills
- Claude Code Skills 文档：https://docs.anthropic.com/claude-code/skills
- UVM Cookbook：https://www.synopsys.com/designware-ip/verification/uvm-cookbook.html
