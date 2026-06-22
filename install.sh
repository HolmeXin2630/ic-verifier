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

# 安装 uvc_gen 依赖
UVC_GEN_REPO="https://github.com/HolmeXin2630/uvc_gen.git"
UVC_GEN_BRANCH="main"
UVC_GEN_DIR="$REPO_DIR/tools/uvc_gen"

echo ""
echo "Installing uvc_gen..."
mkdir -p "$REPO_DIR/tools"

if [ ! -d "$UVC_GEN_DIR" ]; then
    git clone --branch "$UVC_GEN_BRANCH" --depth 1 "$UVC_GEN_REPO" "$UVC_GEN_DIR"
    echo "✅ uvc_gen 已安装到 $UVC_GEN_DIR"
else
    echo "✅ uvc_gen 已存在，跳过安装"
fi

# 检查 Python 依赖
if command -v python3 &> /dev/null; then
    echo "✅ Python3 已安装"
    if [ -f "$UVC_GEN_DIR/requirements.txt" ]; then
        pip3 install -r "$UVC_GEN_DIR/requirements.txt" 2>/dev/null || true
    fi
else
    echo "⚠️  Python3 未安装，uvc_gen 将无法使用"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Installed skills:"
ls -la "$SKILLS_DIR" | grep "^l.*->.*$REPO_DIR" | awk '{print "  " $NF " -> " $0}'
echo ""
echo "Usage: /env-builder in your project directory"
