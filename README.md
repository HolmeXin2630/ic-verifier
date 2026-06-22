# IC Verifier

Claude Code skills for IC verification engineers. Enforces structured, verified SV/UVM development workflows.

## What It Does

When you use `/env-builder`, Claude Code will:

1. **Clarify requirements** before writing any code
2. **Write a spec** for your approval
3. **Create an implementation plan** with verification strategy
4. **Implement with TDD** — test first, code second
5. **Review** against UVM methodology and coding standards
6. **Loop** until all checks pass

No more AI-generated code that "looks like UVM" but doesn't actually work.

## Installation

### 方式一：使用 npx skills（推荐）

支持 68+ 种 AI coding agents，包括 Claude Code、Codex、Cursor、GitHub Copilot 等。

```bash
npx skills add HolmeXin2630/ic-verifier
```

安装完成后，运行安装脚本创建 symlink 和工具：

```bash
# 找到安装路径（npx 输出中会显示）
cd <安装路径>/..
bash install.sh
```

或者在 Claude Code 中运行 `/setup-ic-verifier`，它会自动检测安装位置并配置。

### 方式二：手动安装（仅 Claude Code）

```bash
git clone https://github.com/HolmeXin2630/ic-verifier.git
cd ic-verifier
bash install.sh
```

This creates symlinks in `~/.claude/skills/`:
- `env-builder/` — the UVM environment building skill
- `setup-ic-verifier/` — one-time setup skill

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

### Creating a New Component

```
> /env-builder
> Create an APB UVC with driver, monitor, and sequencer
```

The skill will walk you through requirements → spec → plan → implementation → review.

### Modifying Existing Code

```
> /env-builder
> Add error injection to the AXI driver
```

The skill will use the light flow: understand → clarify scope → TDD → implement → review.

### Reviewing Code

```
> /env-builder
> Review this UVM monitor for methodology issues
```

The skill will review against coding standards and UVM best practices.

## Skills

| Skill | Command | Status |
|-------|---------|--------|
| UVM Environment Builder | `/env-builder` | ✅ Available |
| Testplan Manager | `/testplan` | 🔜 Planned |
| Coverage Closure | `/coverage` | 🔜 Planned |
| Formal Property | `/formal` | 🔜 Planned |

## Project Configuration

The skill uses `.ic-verifier.yml` in your project root:

```yaml
simulator: vcs
compile_cmd: "vcs -full64 -sverilog +incdir+..."
elaborate_cmd: ""
sim_cmd: "./simv +UVM_TESTNAME=..."
lint_cmd: ""
regression_cmd: "make regression"
work_dir: "sim"
```

## License

MIT
