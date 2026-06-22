# Task 1: 修改 install.sh 支持自动 clone uvc_gen

## 任务描述

修改 install.sh 脚本，添加自动 clone uvc_gen 仓库的逻辑。

## 文件修改

- Modify: `install.sh`

## 接口

- Consumes: uvc_gen GitHub 仓库地址 (https://github.com/HolmeXin2630/uvc_gen.git)
- Produces: `tools/uvc_gen/` 目录，包含 uvc_gen.py 和 templates/

## 全局约束

- 必须支持 npx skills 生态系统（68+ 种 agents）
- uvc_gen 通过 install.sh 自动 clone，不使用 Git submodule
- SKILL.md 使用标准格式，符合 npx skills 规范
- 保持向后兼容，支持现有用户升级

## 步骤

### Step 1: 备份当前 install.sh

```bash
cp install.sh install.sh.backup
```

### Step 2: 修改 install.sh 添加 uvc_gen 安装逻辑

在 install.sh 的末尾添加以下代码：

```bash
# 安装 uvc_gen 依赖
UVC_GEN_REPO="https://github.com/HolmeXin2630/uvc_gen.git"
UVC_GEN_BRANCH="main"
UVC_GEN_DIR="$REPO_DIR/tools/uvc_gen"

echo "安装 uvc_gen..."
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
```

### Step 3: 测试 install.sh

```bash
# 测试安装脚本
bash install.sh

# 验证 uvc_gen 是否安装成功
ls -la ~/.claude/skills/ic-verifier/tools/uvc_gen/
```

### Step 4: 提交更改

```bash
git add install.sh
git commit -m "feat: add uvc_gen auto-installation to install.sh"
```
