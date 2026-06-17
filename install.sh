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

echo ""
echo "Installation complete!"
echo ""
echo "Installed skills:"
ls -la "$SKILLS_DIR" | grep "^l.*->.*$REPO_DIR" | awk '{print "  " $NF " -> " $0}'
echo ""
echo "Usage: /env-builder in your project directory"
