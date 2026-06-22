---
name: setup-ic-verifier
description: Configure this repo for IC verification skills — set up knowledge base symlinks and uvc_gen tool. Run once before first use of env-builder.
disable-model-invocation: true
---

# Setup IC Verifier

Scaffold the per-repo configuration that the IC verification skills assume:

- **Knowledge base** — shared coding standards, design patterns, UVC construction guides
- **uvc_gen** — UVC template generator tool

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## Process

### 1. Explore

Look at the current environment to understand its starting state:

- Check if `~/.claude/skills/env-builder` exists (npx installation)
- Check if `~/.claude/skills/ic-verifier` exists (knowledge base)
- Check if `knowledge/` directory exists in the skill location
- Check if `tools/uvc_gen/` exists in the skill location

### 2. Present findings and ask

Summarise what's present and what's missing. Then walk the user through the setup **one step at a time**.

**Section A — Knowledge base symlink.**

> Explainer: The knowledge base contains shared coding standards, design patterns, UVC construction guides, and review frameworks. These files are used by multiple skills (env-builder, future testplan, coverage, formal). Creating a symlink allows all skills to access the same knowledge base.

Check if the knowledge base is already accessible:
- If `~/.claude/skills/ic-verifier/knowledge/` exists and contains files, the knowledge base is already set up
- If not, create the symlink

**Section B — uvc_gen tool.**

> Explainer: uvc_gen is a Python tool that generates UVC templates. It's required for the env-builder skill to create new components.

Check if uvc_gen is already installed:
- If `tools/uvc_gen/uvc_gen.py` exists, uvc_gen is already installed
- If not, clone it from GitHub

**Section C — Python dependencies.**

> Explainer: uvc_gen requires Python 3 with jinja2 and rich packages.

Check if dependencies are installed:
- If Python 3 is available and packages are installed, skip
- If not, install them

### 3. Confirm and execute

Show the user what will be done:
- Create symlink: `~/.claude/skills/ic-verifier` → skill repository
- Clone uvc_gen: `git clone https://github.com/HolmeXin2630/uvc_gen.git`
- Install dependencies: `pip3 install jinja2 rich`

Let them confirm before proceeding.

### 4. Execute

**Step A: Create knowledge base symlink**

```bash
# Find the skill installation directory
SKILL_DIR="$(dirname "$(readlink -f ~/.claude/skills/env-builder)")"

# Create symlink to repository root (parent of skills/)
ln -sf "$SKILL_DIR/../.." ~/.claude/skills/ic-verifier
```

**Step B: Install uvc_gen**

```bash
# Clone uvc_gen into the skill repository
cd ~/.claude/skills/ic-verifier
git clone --depth 1 https://github.com/HolmeXin2630/uvc_gen.git tools/uvc_gen
```

**Step C: Install Python dependencies**

```bash
pip3 install jinja2 rich
```

### 5. Done

Tell the user the setup is complete and the env-builder skill can now access:
- Knowledge base: `~/.claude/skills/ic-verifier/knowledge/`
- uvc_gen tool: `~/.claude/skills/ic-verifier/tools/uvc_gen/`

Mention they can re-run `/setup-ic-verifier` if they need to update the knowledge base or uvc_gen tool.
