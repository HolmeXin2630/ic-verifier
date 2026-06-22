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

Look at the current environment:

- Check if `~/.agents/skills/env-builder/` exists
- Check if `~/.agents/skills/ic-verifier/knowledge/` exists and has files
- Check if `~/.agents/skills/env-builder/knowledge` is a symlink pointing to `../ic-verifier/knowledge`
- Check if uvc_gen is installed (search for `uvc_gen.py` in common locations)

### 2. Present findings and ask

Summarise what's present and what's missing. Walk the user through setup **one step at a time**.

**Section A — Knowledge base symlink.**

The knowledge base contains shared coding standards, design patterns, UVC construction guides, and review frameworks. Creating a symlink allows all skills to access the same knowledge base without duplication.

Check: does `~/.agents/skills/env-builder/knowledge` exist as a symlink to `../ic-verifier/knowledge`?

- If yes and the target has files → knowledge is set up
- If the directory exists but is NOT a symlink → needs migration (back up files, create symlink)
- If missing → create the symlink

**Section B — uvc_gen tool.**

uvc_gen is a Python tool that generates UVC templates. Required for the env-builder skill when creating UVC/VIP components.

Search for `uvc_gen.py` in:
1. `~/.agents/skills/ic-verifier/tools/uvc_gen/uvc_gen.py`
2. `~/.agents/skills/env-builder/tools/uvc_gen/uvc_gen.py`

If not found, clone it.

**Section C — Python dependencies.**

uvc_gen requires Python 3 with jinja2 and rich packages.

### 3. Confirm and execute

Show the user what will be done:
- Create symlink: `~/.agents/skills/env-builder/knowledge` → `../ic-verifier/knowledge`
- Clone uvc_gen: `git clone https://github.com/HolmeXin2630/uvc_gen.git`
- Install dependencies: `pip3 install jinja2 rich`

Let them confirm before proceeding.

### 4. Execute

**Step A: Create knowledge base symlink**

```bash
# Ensure shared knowledge directory exists
mkdir -p ~/.agents/skills/ic-verifier/knowledge

# If env-builder has a real directory (not symlink), migrate files first
if [ -d ~/.agents/skills/env-builder/knowledge ] && [ ! -L ~/.agents/skills/env-builder/knowledge ]; then
    cp ~/.agents/skills/env-builder/knowledge/*.md ~/.agents/skills/ic-verifier/knowledge/
    rm -rf ~/.agents/skills/env-builder/knowledge
fi

# Create symlink
ln -sf ../ic-verifier/knowledge ~/.agents/skills/env-builder/knowledge
```

**Step B: Install uvc_gen**

```bash
cd ~/.agents/skills/ic-verifier
git clone --depth 1 https://github.com/HolmeXin2630/uvc_gen.git tools/uvc_gen
```

**Step C: Install Python dependencies**

```bash
pip3 install jinja2 rich
```

### 5. Done

Tell the user the setup is complete. The env-builder skill can now access:
- Knowledge base: `~/.agents/skills/env-builder/knowledge/` (symlink to shared directory)
- uvc_gen tool: `~/.agents/skills/ic-verifier/tools/uvc_gen/`

Mention they can re-run `/setup-ic-verifier` if they need to update the knowledge base or uvc_gen tool.
