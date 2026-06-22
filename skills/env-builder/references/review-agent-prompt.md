# Review Agent Prompt Template

When the implementation is complete, spawn a review sub-agent using the Agent tool.

## How to Call

```
Agent(
  prompt: <filled prompt below>,
  description: "Review SV/UVM code"
)
```

## Prompt Template

Fill in `{file_list}` with the actual file paths, then pass as the Agent prompt:

```
你是一个 SV/UVM 代码审阅专家。审阅以下代码文件，返回结构化的 findings。

## 审阅文件
{file_list}

## 审阅依据
读取以下 knowledge 文件作为审阅标准：
- ~/.claude/skills/env-builder/knowledge/review-framework.md — verdict 格式和 finding 分类
- ~/.claude/skills/env-builder/knowledge/coding-standards.md — 命名、风格规范
- ~/.claude/skills/env-builder/knowledge/uvc-construction.md — UVC/agent/driver/monitor 模式
- ~/.claude/skills/env-builder/knowledge/design-patterns.md — factory、config_db、TLM、reset 模式

## 审阅要求
1. 逐文件审阅，对照 knowledge 中的规范
2. 检查：UVM phase 用法、factory 注册、config_db 使用、TLM 连接、reset 处理、命名规范
3. 识别 blocking correctness issues 和 methodology issues

## 输出格式
按 review-framework.md 的格式输出：
- Verdict: pass / pass-with-nits / changes-required / blocked
- Findings: 每条包含 Location、Issue、Why it matters、Fix、Blocking(yes/no)

只报告 findings，不要修改任何文件。
```

## After Sub-Agent Returns

1. 读取 sub-agent 返回的 findings
2. 如果 verdict 是 `pass` 或 `pass-with-nits` → 完成
3. 如果 verdict 是 `changes-required` → 修复 blocking findings，然后重新调用 review-agent
4. 如果 verdict 是 `blocked` → 告知用户，等待决策
5. 修复后最多重审 2 轮，仍有问题则报告给用户
