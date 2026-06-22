#!/usr/bin/env bash
set -euo pipefail

# IC Verifier Installation Script
# Sets up shared knowledge symlinks and installs uvc_gen tool.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== IC Verifier Setup ==="
echo "Knowledge source: $SCRIPT_DIR/knowledge/"
echo "Skills directory: $SKILLS_DIR/"
echo ""

# --- Step A: Knowledge symlink for env-builder ---
echo "[1/3] Setting up knowledge symlink for env-builder..."

ENV_BUILDER="$SKILLS_DIR/env-builder"
if [ ! -d "$ENV_BUILDER" ]; then
    echo "  SKIP: env-builder skill not found at $ENV_BUILDER"
else
    if [ -L "$ENV_BUILDER/knowledge" ]; then
        echo "  OK: symlink already exists ($(readlink "$ENV_BUILDER/knowledge"))"
    elif [ -d "$ENV_BUILDER/knowledge" ]; then
        echo "  Migrating: real directory → symlink"
        # Copy existing files to shared location
        cp "$ENV_BUILDER/knowledge/"*.md "$SCRIPT_DIR/knowledge/" 2>/dev/null || true
        rm -rf "$ENV_BUILDER/knowledge"
        ln -sf ../ic-verifier/knowledge "$ENV_BUILDER/knowledge"
        echo "  Created: $ENV_BUILDER/knowledge -> ../ic-verifier/knowledge"
    else
        ln -sf ../ic-verifier/knowledge "$ENV_BUILDER/knowledge"
        echo "  Created: $ENV_BUILDER/knowledge -> ../ic-verifier/knowledge"
    fi
fi

# Add more skills here as they are created:
# for skill in testplan coverage formal; do
#     SKILL_DIR="$SKILLS_DIR/$skill"
#     if [ -d "$SKILL_DIR" ] && [ ! -L "$SKILL_DIR/knowledge" ]; then
#         ln -sf ../ic-verifier/knowledge "$SKILL_DIR/knowledge"
#         echo "  Created symlink for $skill"
#     fi
# done

# --- Step B: Install uvc_gen ---
echo ""
echo "[2/3] Installing uvc_gen..."

UVC_GEN_DIR="$SCRIPT_DIR/tools/uvc_gen"
if [ -f "$UVC_GEN_DIR/uvc_gen.py" ]; then
    echo "  OK: uvc_gen already installed"
else
    mkdir -p "$SCRIPT_DIR/tools"
    echo "  Cloning uvc_gen..."
    git clone --depth 1 https://github.com/HolmeXin2630/uvc_gen.git "$UVC_GEN_DIR"
    echo "  Installed: $UVC_GEN_DIR"
fi

# --- Step C: Python dependencies ---
echo ""
echo "[3/3] Checking Python dependencies..."

if python3 -c "import jinja2; import rich" 2>/dev/null; then
    echo "  OK: jinja2 and rich already installed"
else
    echo "  Installing jinja2 and rich..."
    pip3 install jinja2 rich
fi

# --- Done ---
echo ""
echo "=== Installation Complete ==="
echo ""
echo "Knowledge files:"
ls "$SCRIPT_DIR/knowledge/"
echo ""
echo "uvc_gen: $UVC_GEN_DIR/uvc_gen.py"
echo ""
echo "Usage: /env-builder in your project directory"
