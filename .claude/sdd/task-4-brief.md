# Task 4: 更新 README.md 支持 npx skills 安装

## 任务描述

更新 README.md，添加 npx skills 安装说明和多 agent 支持。

## 文件修改

- Modify: `README.md`

## 接口

- Consumes: npx skills CLI
- Produces: 安装说明文档

## 全局约束

- 必须支持 npx skills 生态系统（68+ 种 agents）
- uvc_gen 通过 install.sh 自动 clone，不使用 Git submodule
- 保持向后兼容，支持现有用户升级

## 步骤

### Step 1: 在 README.md 的 Installation 部分添加 npx skills 安装方式

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

### Step 2: 在 Usage 部分添加多 agent 使用说明

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

### Step 3: 提交更改

```bash
git add README.md
git commit -m "docs: add npx skills installation and multi-agent support"
```
