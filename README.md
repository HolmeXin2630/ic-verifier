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

```bash
git clone https://github.com/YOUR_USERNAME/ic-verifier.git
cd ic-verifier
bash install.sh
```

This creates symlinks in `~/.claude/skills/`:
- `ic-verifier/` — shared knowledge (coding standards, review framework)
- `env-builder/` — the UVM environment building skill

## Usage

### First Use (in your project)

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
