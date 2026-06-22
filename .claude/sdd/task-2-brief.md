# Task 2: 修改 SKILL.md 添加 uvc_gen 集成逻辑

## 任务描述

在 SKILL.md 中添加 uvc_gen 检测和调用逻辑，使 env-builder skill 能够自动调用 uvc_gen 生成 UVM 验证组件模板。

## 文件修改

- Modify: `skills/env-builder/SKILL.md`

## 接口

- Consumes: `tools/uvc_gen/uvc_gen.py` 脚本
- Produces: 生成的 UVC 模板代码

## 全局约束

- 必须支持 npx skills 生态系统（68+ 种 agents）
- uvc_gen 通过 install.sh 自动 clone，不使用 Git submodule
- SKILL.md 使用标准格式，符合 npx skills 规范
- 保持向后兼容，支持现有用户升级

## 步骤

### Step 1: 在 SKILL.md 的 Full Flow 中添加 uvc_gen 检测逻辑

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

### Step 2: 在 Step 1 之后添加参数推断逻辑

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

### Step 3: 在 Step 2 之后添加 uvc_gen 调用逻辑

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

### Step 4: 提交更改

```bash
git add skills/env-builder/SKILL.md
git commit -m "feat: add uvc_gen integration logic to SKILL.md"
```
