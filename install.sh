#!/usr/bin/env bash
set -euo pipefail

# IC Verifier Installation Script
# Works for both manual clone and npx skills installation.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

echo "=== IC Verifier Setup ==="
echo "Source: $SCRIPT_DIR"
echo ""

# --- Step 1: Create ~/.claude/skills/ symlinks ---
echo "[1/4] Checking Claude Code skill symlinks..."

mkdir -p "$CLAUDE_SKILLS_DIR"

create_skill_symlink() {
    local skill_name="$1"
    local skill_path="$2"
    local link_path="$CLAUDE_SKILLS_DIR/$skill_name"

    if [ -L "$link_path" ]; then
        local current_target
        current_target="$(readlink -f "$link_path")"
        local expected_target
        expected_target="$(readlink -f "$skill_path")"
        if [ "$current_target" = "$expected_target" ]; then
            echo "  ✅ $skill_name (already linked)"
        else
            echo "  🔄 $skill_name (updating target)"
            rm "$link_path"
            ln -s "$skill_path" "$link_path"
        fi
    elif [ -d "$link_path" ]; then
        echo "  ⚠️  $skill_name: exists as real directory, skipping"
        echo "     Remove manually if you want a symlink: rm -rf $link_path"
    else
        ln -s "$skill_path" "$link_path"
        echo "  ✅ $skill_name (created)"
    fi
}

# Detect skill locations — works for repo clone and npx-installed structures
if [ -d "$SCRIPT_DIR/skills/env-builder" ]; then
    # Repo structure: skills are in skills/ subdirectory
    ENV_BUILDER_DIR="$SCRIPT_DIR/skills/env-builder"
    SETUP_DIR="$SCRIPT_DIR/skills/setup-ic-verifier"
elif [ -f "$SCRIPT_DIR/SKILL.md" ]; then
    # npx-installed: we ARE the env-builder directory
    ENV_BUILDER_DIR="$SCRIPT_DIR"
    SETUP_DIR=""
else
    echo "  ERROR: Cannot find skill directories. Run from the ic-verifier repo root."
    exit 1
fi

create_skill_symlink "env-builder" "$ENV_BUILDER_DIR"
if [ -n "$SETUP_DIR" ] && [ -d "$SETUP_DIR" ]; then
    create_skill_symlink "setup-ic-verifier" "$SETUP_DIR"
fi

# --- Step 2: Knowledge symlink ---
echo ""
echo "[2/4] Setting up knowledge symlink..."

# Find the knowledge source (shared directory in repo root)
KNOWLEDGE_SRC=""
if [ -d "$SCRIPT_DIR/knowledge" ]; then
    KNOWLEDGE_SRC="$SCRIPT_DIR/knowledge"
elif [ -d "$(dirname "$ENV_BUILDER_DIR")/../knowledge" ]; then
    KNOWLEDGE_SRC="$(cd "$(dirname "$ENV_BUILDER_DIR")/../knowledge" && pwd)"
fi

if [ -n "$KNOWLEDGE_SRC" ] && [ -d "$KNOWLEDGE_SRC" ]; then
    if [ -d "$ENV_BUILDER_DIR/knowledge" ] && [ ! -L "$ENV_BUILDER_DIR/knowledge" ]; then
        echo "  Migrating: real directory → symlink"
        cp "$ENV_BUILDER_DIR/knowledge/"*.md "$KNOWLEDGE_SRC/" 2>/dev/null || true
        rm -rf "$ENV_BUILDER_DIR/knowledge"
        ln -sf "$(realpath --relative-to="$ENV_BUILDER_DIR" "$KNOWLEDGE_SRC")" "$ENV_BUILDER_DIR/knowledge"
        echo "  ✅ Created symlink"
    elif [ -L "$ENV_BUILDER_DIR/knowledge" ]; then
        echo "  ✅ Symlink already exists ($(readlink "$ENV_BUILDER_DIR/knowledge"))"
    elif [ ! -e "$ENV_BUILDER_DIR/knowledge" ]; then
        ln -sf "$(realpath --relative-to="$ENV_BUILDER_DIR" "$KNOWLEDGE_SRC")" "$ENV_BUILDER_DIR/knowledge"
        echo "  ✅ Created symlink"
    fi
else
    echo "  ⚠️  Knowledge source not found, skipping"
fi

# --- Step 3: uvc_gen ---
echo ""
echo "[3/4] Installing uvc_gen..."

UVC_GEN_DIR="$SCRIPT_DIR/tools/uvc_gen"
if [ -f "$UVC_GEN_DIR/uvc_gen.py" ]; then
    echo "  ✅ Already installed"
else
    mkdir -p "$SCRIPT_DIR/tools"
    echo "  Cloning uvc_gen..."
    if git clone --depth 1 https://github.com/HolmeXin2630/uvc_gen.git "$UVC_GEN_DIR" 2>&1; then
        echo "  ✅ Installed"
    else
        echo "  ❌ Clone failed — uvc_gen will not be available"
        echo "     Manual install: git clone https://github.com/HolmeXin2630/uvc_gen.git $UVC_GEN_DIR"
    fi
fi

# --- Step 4: Python dependencies ---
echo ""
echo "[4/4] Checking Python dependencies..."

if python3 -c "import jinja2; import rich" 2>/dev/null; then
    echo "  ✅ jinja2 and rich installed"
else
    echo "  Installing jinja2 and rich..."
    pip3 install jinja2 rich
fi

# --- Done ---
echo ""
echo "=== Installation Complete ==="
echo ""
echo "Skills available at:"
echo "  ~/.claude/skills/env-builder"
[ -L "$CLAUDE_SKILLS_DIR/setup-ic-verifier" ] && echo "  ~/.claude/skills/setup-ic-verifier"
echo ""
echo "Usage: /env-builder in your project directory"
echo "       /setup-ic-verifier for first-time setup"
