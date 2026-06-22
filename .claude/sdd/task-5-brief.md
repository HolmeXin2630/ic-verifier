# Task 5: 更新知识库文档

## 任务描述

更新 uvc-construction.md 和 coding-standards.md，添加 uvc_gen 集成说明。

## 文件修改

- Modify: `knowledge/uvc-construction.md`
- Modify: `knowledge/coding-standards.md`

## 接口

- Consumes: uvc_gen 生成的模板代码风格
- Produces: 更新后的编码规范和 UVC 构建指南

## 全局约束

- 必须支持 npx skills 生态系统（68+ 种 agents）
- uvc_gen 通过 install.sh 自动 clone，不使用 Git submodule
- 保持向后兼容，支持现有用户升级

## 步骤

### Step 1: 在 uvc-construction.md 中添加 uvc_gen 集成说明

在 `## UVC 构建流程` 部分添加：

```markdown
## uvc_gen 集成

### 自动生成模板

env-builder skill 集成了 uvc_gen 工具，可以自动生成符合 UVM 规范的代码框架。

**使用方式：**
- 创建新 UVC 时，skill 会自动调用 uvc_gen 生成模板
- 生成的模板包含：agent、driver、monitor、sequencer、transaction 等组件
- 支持 single 和 mstslv 两种模式

**模板定制：**
- 生成的模板可以作为起点进行定制开发
- 遵循模板的代码风格和命名规范
- 可以基于模板进行迭代优化

### 迭代优化

当模板不完全满足需求时，可以使用 Iteration Flow：
1. 分析现有模板结构
2. 识别缺失的组件或功能
3. 参考模板风格进行补全
4. 保持代码一致性
```

### Step 2: 在 coding-standards.md 中添加 uvc_gen 代码风格说明

在 `## 命名规范` 部分添加：

```markdown
## uvc_gen 代码风格

uvc_gen 生成的代码遵循以下规范：

### 命名约定
- 类名：`{uvc_name}_{component}` (如 `ahb_driver`)
- 文件名：`{uvc_name}_{component}.sv` (如 `ahb_driver.sv`)
- 接口名：`{uvc_name}_if` (如 `ahb_if`)

### 代码结构
- 使用 UVM 标准宏：`uvm_component_utils`, `uvm_field_utils`
- 遵循 UVM phase 机制
- 使用 config_db 进行配置

### 模板变量
- 使用 `uvc_info` 对象访问 UVC 参数
- 支持模板变量替换
- 保持代码可读性
```

### Step 3: 提交更改

```bash
git add knowledge/uvc-construction.md knowledge/coding-standards.md
git commit -m "docs: add uvc_gen integration and code style guidelines"
```
