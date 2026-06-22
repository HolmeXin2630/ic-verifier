#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo "Installing IC Verifier skills..."
echo "Source: $REPO_DIR"
echo "Target: $SKILLS_DIR"
echo ""

mkdir -p "$SKILLS_DIR"

# Shared knowledge
LINK_NAME="$SKILLS_DIR/ic-verifier"
if [ -L "$LINK_NAME" ]; then
    echo "Updating symlink: ic-verifier"
    rm "$LINK_NAME"
elif [ -d "$LINK_NAME" ]; then
    echo "WARNING: $LINK_NAME exists and is not a symlink. Skipping."
    echo "  Remove it manually if you want to reinstall."
fi
if [ ! -e "$LINK_NAME" ]; then
    ln -s "$REPO_DIR" "$LINK_NAME"
    echo "Created symlink: ic-verifier -> $REPO_DIR"
fi

# Domain skills
for skill_dir in "$REPO_DIR"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    LINK_NAME="$SKILLS_DIR/$skill_name"

    if [ -L "$LINK_NAME" ]; then
        echo "Updating symlink: $skill_name"
        rm "$LINK_NAME"
    elif [ -d "$LINK_NAME" ]; then
        echo "WARNING: $LINK_NAME exists and is not a symlink. Skipping."
        echo "  Remove it manually if you want to reinstall."
        continue
    fi

    if [ ! -e "$LINK_NAME" ]; then
        ln -s "$skill_dir" "$LINK_NAME"
        echo "Created symlink: $skill_name -> $skill_dir"
    fi
done

# Install uvc_gen
UVC_GEN_REPO="https://github.com/HolmeXin2630/uvc_gen.git"
UVC_GEN_BRANCH="main"
UVC_GEN_DIR="$REPO_DIR/tools/uvc_gen"

echo ""
echo "Installing uvc_gen..."
mkdir -p "$REPO_DIR/tools"

if [ ! -d "$UVC_GEN_DIR" ]; then
    echo "Cloning uvc_gen from $UVC_GEN_REPO ..."
    if ! git clone --branch "$UVC_GEN_BRANCH" --depth 1 "$UVC_GEN_REPO" "$UVC_GEN_DIR" 2>&1; then
        echo "ERROR: git clone failed. Please check your network and try again."
        echo "  You can also manually clone: git clone $UVC_GEN_REPO $UVC_GEN_DIR"
        echo "  Continuing without uvc_gen..."
        UVC_GEN_CLONE_FAILED=true
    else
        echo "uvc_gen installed to $UVC_GEN_DIR"
    fi
else
    echo "uvc_gen already exists, skipping installation"
fi

# Install Python dependencies
# NOTE: We hardcode the two required packages (jinja2, rich) rather than
# parsing pyproject.toml, because pyproject.toml may specify version ranges
# or extras that are not needed at install time. This keeps the installer
# simple and avoids requiring additional tools (e.g., pip's pyproject parser).
if [ "${UVC_GEN_CLONE_FAILED:-false}" = "true" ]; then
    echo "WARNING: uvc_gen clone failed, skipping dependency installation"
elif command -v python3 &> /dev/null; then
    echo "Python3 is installed"
    if [ -f "$UVC_GEN_DIR/pyproject.toml" ]; then
        echo "Installing uvc_gen dependencies (jinja2, rich)..."
        pip3 install jinja2 rich 2>/dev/null || pip install jinja2 rich 2>/dev/null || true
    fi
else
    echo "WARNING: Python3 is not installed, uvc_gen will not be available"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Installed skills:"
ls -la "$SKILLS_DIR" | grep "^l.*->.*$REPO_DIR" | awk '{print "  " $NF " -> " $0}'
echo ""
echo "Usage: /env-builder in your project directory"
