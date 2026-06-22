---
name: setup-ic-verifier
description: Configure this repo for IC verification skills — set up knowledge base symlinks and uvc_gen tool. Run once before first use of env-builder.
disable-model-invocation: true
---

# Setup IC Verifier

Scaffold the configuration that IC verification skills need:

- **Skill symlinks** — ensure `~/.claude/skills/` can find the skills
- **Knowledge base** — shared coding standards, design patterns, UVC construction guides
- **uvc_gen** — UVC template generator tool

This is a prompt-driven skill. Explore the environment, present findings, confirm with the user, then execute.

## Process

### 1. Explore

Find where the skills are actually installed. Check these locations in order:

1. **`~/.claude/skills/env-builder/`** — already symlinked? Read the symlink target.
2. **`~/.agents/skills/env-builder/`** — user-level npx install.
3. **`<project>/.agents/skills/env-builder/`** — project-level npx install. Search upward from cwd for `.agents/skills/env-builder/`.
4. **Manual clone** — check if `skills/env-builder/` exists relative to the ic-verifier repo root.

Once found, determine:
- Is `~/.claude/skills/env-builder` a valid symlink? → `ls -la ~/.claude/skills/env-builder`
- Does `knowledge/` exist inside the env-builder directory?
- Is it a symlink or a real directory?
- Is uvc_gen installed? Search for `uvc_gen.py` next to the skill.

### 2. Present findings and ask

Summarise what's present and what's missing. Walk through setup one step at a time.

**Section A — Skill symlinks (if missing).**

If `~/.claude/skills/env-builder` doesn't exist or points to the wrong place, create it:

```bash
# Find the actual env-builder directory (from step 1)
ENV_BUILDER_DIR="<discovered path>"
mkdir -p ~/.claude/skills
ln -sf "$ENV_BUILDER_DIR" ~/.claude/skills/env-builder
```

**Section B — Knowledge base.**

The knowledge base is shared across skills. If `knowledge/` inside env-builder is a real directory (not a symlink), and a shared `knowledge/` exists at the repo root, create a symlink instead:

```bash
# Only if repo root knowledge/ exists and env-builder/knowledge/ is a real dir
if [ -d "<repo-root>/knowledge" ] && [ -d "$ENV_BUILDER_DIR/knowledge" ] && [ ! -L "$ENV_BUILDER_DIR/knowledge" ]; then
    cp "$ENV_BUILDER_DIR/knowledge/"*.md "<repo-root>/knowledge/" 2>/dev/null
    rm -rf "$ENV_BUILDER_DIR/knowledge"
    ln -sf "<relative-path-to-repo-root>/knowledge" "$ENV_BUILDER_DIR/knowledge"
fi
```

If `knowledge/` is already a symlink or already has files, skip.

**Section C — uvc_gen tool.**

uvc_gen generates UVC templates. Search for `uvc_gen.py` in:
1. Next to the skill: `<skill-dir>/tools/uvc_gen/uvc_gen.py`
2. In repo root: `<repo-root>/tools/uvc_gen/uvc_gen.py`

If not found, clone:
```bash
git clone --depth 1 https://github.com/HolmeXin2630/uvc_gen.git <target-dir>/tools/uvc_gen
```

**Section D — Python dependencies.**

uvc_gen requires jinja2 and rich:
```bash
pip3 install jinja2 rich
```

### 3. Confirm and execute

Show the user what will be done. Let them confirm before proceeding.

### 4. Done

Tell the user the setup is complete. Mention they can re-run `/setup-ic-verifier` if needed.
