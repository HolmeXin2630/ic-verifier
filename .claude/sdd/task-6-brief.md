# Task 6: 测试完整流程

## 任务描述

测试 npx skills 安装、install.sh、Full Flow 和 Iteration Flow。

## 文件修改

- Test: 无新文件，测试现有功能

## 接口

- Consumes: npx skills CLI, uvc_gen 脚本
- Produces: 测试报告

## 全局约束

- 必须支持 npx skills 生态系统（68+ 种 agents）
- uvc_gen 通过 install.sh 自动 clone，不使用 Git submodule
- 保持向后兼容，支持现有用户升级

## 步骤

### Step 1: 测试 npx skills 安装

```bash
# 测试 npx skills 安装
npx skills add HolmeXin2630/ic-verifier

# 验证安装
ls -la ~/.claude/skills/ic-verifier
```

### Step 2: 测试 install.sh

```bash
# 进入 skill 目录
cd ~/.claude/skills/ic-verifier

# 运行 install.sh
bash install.sh

# 验证 uvc_gen 安装
ls -la tools/uvc_gen/uvc_gen.py
```

### Step 3: 测试 Full Flow

在 AI agent 中运行：
```
> /env-builder
> Create an AHB UVC with driver, monitor, and sequencer
```

验证：
1. skill 检测到 uvc_gen 可用
2. 自动推断参数（uvc_name=ahb, mode=single）
3. 调用 uvc_gen 生成模板
4. 继续后续流程

### Step 4: 测试 Iteration Flow

在 AI agent 中运行：
```
> /env-builder
> 模板缺少 scoreboard，需要添加
```

验证：
1. skill 识别为 Iteration Flow
2. 分析现有模板
3. 参考模板风格添加 scoreboard
4. 保持代码一致性

### Step 5: 提交测试结果

```bash
git add -A
git commit -m "test: verify uvc_gen integration and Iteration Flow"
```
