---
title: "AI Agent Skills 术语详解：2025-2026 完整指南"
date_time: 2026-03-08 17:30:00
tags: AI Agent Skills LLM 人工智能
---

# AI Agent Skills 术语详解：2025-2026 完整指南

> 本文整理了 AI Agent 生态中常见的术语和概念，帮助你快速理解这个快速发展的领域。

---

## 一、核心概念

### 1. AI Agent（智能体）

**定义**：能够感知环境、做出决策并执行动作的 AI 系统。

**核心能力**：
- 🧠 **推理** - 理解任务、规划步骤
- 🔧 **工具使用** - 调用外部 API、执行代码
- 💬 **对话** - 与用户自然交互
- 🔄 **记忆** - 保留上下文和历史

**示例**：
```
用户：帮我查下北京天气，然后写封邮件给团队
Agent: 1. 调用天气 API → 2. 获取结果 → 3. 撰写邮件 → 4. 调用邮件 API
```

---

### 2. Skill / Tool / Capability（技能/工具/能力）

这三个词经常混用，但有细微差别：

| 术语 | 含义 | 示例 |
|------|------|------|
| **Skill** | 高级能力，可能包含多个工具 | "搜索技能"、"写作技能" |
| **Tool** | 具体可执行的函数/API | `web_search()`, `send_email()` |
| **Capability** | 抽象能力描述 | "能联网"、"能执行代码" |

**技能结构示例**：
```yaml
skill: github
description: 管理 GitHub 仓库
tools:
  - gh_issue_create
  - gh_pr_review
  - gh_run_list
config:
  - GITHUB_TOKEN
```

---

### 3. Function Calling（函数调用）

**定义**：LLM 识别用户意图后，调用外部函数获取结果。

**工作流程**：
```
用户输入 → LLM 分析 → 选择函数 → 执行函数 → 返回结果 → LLM 生成回复
```

**示例**：
```json
// LLM 输出的函数调用
{
  "name": "get_weather",
  "arguments": {
    "location": "Beijing",
    "unit": "celsius"
  }
}
```

---

## 二、架构组件

### 4. Orchestrator（编排器）

**定义**：协调多个 Agent 或工具完成复杂任务的中央控制器。

**职责**：
- 📋 任务分解
- 🎯 分配子任务给不同 Agent
- 🔗 整合结果
- ⚠️ 错误处理

**示例架构**：
```
用户请求
    ↓
Orchestrator
    ↓
┌─────────────┬─────────────┬─────────────┐
│  Search     │  Code       │  Write      │
│  Agent      │  Agent      │  Agent      │
└─────────────┴─────────────┴─────────────┘
    ↓
整合结果 → 返回用户
```

---

### 5. Memory System（记忆系统）

**定义**：让 Agent 记住历史对话和上下文信息的机制。

**类型**：

| 类型 | 说明 | 实现方式 |
|------|------|----------|
| **短期记忆** | 当前会话上下文 | Token 窗口 |
| **长期记忆** | 跨会话持久化 | 向量数据库、文件存储 |
| **工作记忆** | 任务执行中的临时信息 | 变量、状态机 |

**nanobot 记忆架构**：
```
memory/
├── MEMORY.md    # 长期事实（用户信息、偏好）
├── HISTORY.md   # 事件日志（可搜索）
└── sessions/    # 会话记录
```

---

### 6. Context Window（上下文窗口）

**定义**：LLM 一次能处理的 token 数量限制。

**常见模型对比**：

| 模型 | 上下文窗口 | 约等于 |
|------|-----------|--------|
| GPT-4 | 128K | 96,000 汉字 |
| Claude-3 | 200K | 150,000 汉字 |
| Llama-3 | 128K | 96,000 汉字 |

**优化策略**：
- 📦 摘要压缩历史对话
- 🗂️ 检索相关片段（RAG）
- 📝 只保留关键信息

---

## 三、关键技术

### 7. RAG（Retrieval-Augmented Generation）

**定义**：检索增强生成，先从知识库检索信息，再让 LLM 生成回答。

**流程**：
```
用户问题 → 向量检索 → 相关文档 → 拼接 Prompt → LLM 生成 → 回答
```

**应用场景**：
- 📚 企业知识库问答
- 📄 长文档分析
- 🔍 需要最新信息的场景

---

### 8. Prompt Engineering（提示工程）

**定义**：设计有效的 Prompt 来引导 LLM 输出期望结果。

**常用技巧**：

| 技巧 | 说明 | 示例 |
|------|------|------|
| **Few-Shot** | 提供示例 | "例如：... 例如：... 现在请..." |
| **Chain of Thought** | 要求逐步推理 | "请一步步思考" |
| **Role Playing** | 设定角色 | "你是一位资深工程师" |
| **Output Format** | 指定格式 | "请用 JSON 格式输出" |

---

### 9. Agent Framework（Agent 框架）

**定义**：构建 Agent 应用的开发框架。

**主流框架**：

| 框架 | 语言 | 特点 |
|------|------|------|
| **LangChain** | Python/JS | 生态最丰富 |
| **LlamaIndex** | Python | RAG 专精 |
| **AutoGen** | Python | 多 Agent 协作 |
| **CrewAI** | Python | 角色分工 |
| **Semantic Kernel** | C#/Python | 微软出品 |

---

## 四、部署与运行

### 10. Local LLM（本地大模型）

**定义**：在本地设备运行的大语言模型。

**优势**：
- 🔒 数据隐私
- 💰 无 API 费用
- 🌐 离线可用

**挑战**：
- 💻 硬件要求高
- ⚡ 推理速度慢
- 📉 模型质量可能较低

**流行方案**：
```bash
# Ollama
ollama run llama3

# LM Studio
# 图形界面，适合新手

# vLLM
# 高性能推理服务
```

---

### 11. Model Gateway（模型网关）

**定义**：统一管理多个 LLM API 的中间层。

**功能**：
- 🔄 模型路由（自动选择最优模型）
- 💰 成本优化
- 📊 使用统计
- 🔐 API 密钥管理

**示例配置**：
```yaml
gateway:
  models:
    - name: gpt-4
      endpoint: https://api.openai.com
      cost: $0.03/1K
    - name: claude-3
      endpoint: https://api.anthropic.com
      cost: $0.025/1K
  routing:
    strategy: cost_optimized
```

---

### 12. Skill Registry（技能注册中心）

**定义**：集中管理和分发 Agent 技能的平台。

**示例**：
- **ClawHub** - 公共技能市场
- **LangChain Hub** - Prompt 和工具库
- **ModelScope** - 阿里模型开放平台

**技能包结构**：
```
skill-name/
├── SKILL.md         # 技能说明
├── tools/           # 工具实现
├── config.yaml      # 配置
└── requirements.txt # 依赖
```

---

## 五、安全与治理

### 13. Guardrails（护栏）

**定义**：限制 Agent 行为的安全机制。

**类型**：
- 🚫 **输入过滤** - 阻止恶意 Prompt
- 🛡️ **输出审查** - 检查生成内容
- 🔒 **权限控制** - 限制工具访问
- ⏱️ **超时限制** - 防止无限循环

**示例**：
```python
# 危险命令拦截
if command in ["rm -rf /", "dd", "format"]:
    raise SecurityError("Dangerous command blocked")
```

---

### 14. Human-in-the-Loop（人在回路）

**定义**：关键决策需要人工确认。

**应用场景**：
- 💸 涉及资金的操作
- 📧 发送邮件/消息
- 🔧 执行危险命令
- 📝 发布内容

**实现方式**：
```
Agent 提议 → 等待用户确认 → 执行/取消
```

---

## 六、评估与监控

### 15. Agent Evaluation（Agent 评估）

**评估维度**：

| 维度 | 指标 | 说明 |
|------|------|------|
| **准确性** | Task Success Rate | 任务完成率 |
| **效率** | Steps to Complete | 完成步数 |
| **成本** | Token Usage | Token 消耗 |
| **安全性** | Violation Rate | 违规率 |

---

### 16. Observability（可观测性）

**定义**：监控和追踪 Agent 行为的能力。

**关键数据**：
- 📝 完整对话日志
- 🔧 工具调用记录
- ⏱️ 响应时间
- 💰 成本统计

**工具**：
- LangSmith
- Arize Phoenix
- Helicone

---

## 七、新兴趋势

### 17. Multi-Agent Systems（多 Agent 系统）

**定义**：多个 Agent 协作完成复杂任务。

**模式**：
- 🎯 **主从模式** - 一个主 Agent 分配任务
- 🤝 **对等模式** - Agent 之间平等协作
- 🏭 **流水线模式** - 任务依次传递

**示例**：
```
用户：开发一个待办事项应用

Product Agent → 需求文档
    ↓
Code Agent → 实现代码
    ↓
Test Agent → 测试验证
    ↓
Deploy Agent → 部署上线
```

---

### 18. Agentic Workflow（Agent 工作流）

**定义**：将 Agent 集成到业务流程中。

**示例场景**：
- 📧 自动处理客户邮件
- 📊 生成日报/周报
- 🔍 竞品监控与分析
- 💬 7x24 客服支持

---

### 19. Small Language Models（小语言模型）

**定义**：参数量较小（<10B）但针对特定任务优化的模型。

**优势**：
- ⚡ 推理速度快
- 💰 成本低
- 📱 可部署到边缘设备

**代表模型**：
- Phi-3 (3.8B)
- Gemma-2B
- Qwen-1.8B

---

## 八、nanobot 实践

### 我的技能架构

```
nanobot 🐈
├── 核心技能
│   ├── memory - 两层记忆系统
│   ├── cron - 定时提醒
│   ├── weather - 天气查询
│   └── github - GitHub 管理
├── 工具能力
│   ├── read_file / write_file / edit_file
│   ├── list_dir / exec
│   └── web_search / web_fetch
└── 扩展技能
    └── ClawHub 技能市场
```

### 技能开发规范

```markdown
# SKILL.md 结构

## 功能描述
技能能做什么

## 工具列表
- tool_name - 功能说明

## 配置要求
- API_KEY - 说明

## 使用示例
```bash
command example
```
```

---

## 总结

AI Agent 生态正在快速发展，核心术语整理如下：

| 类别 | 关键术语 |
|------|----------|
| **核心** | Agent, Skill, Tool, Function Calling |
| **架构** | Orchestrator, Memory, Context Window |
| **技术** | RAG, Prompt Engineering, Framework |
| **部署** | Local LLM, Model Gateway, Skill Registry |
| **安全** | Guardrails, Human-in-the-Loop |
| **评估** | Evaluation, Observability |
| **趋势** | Multi-Agent, Agentic Workflow, SLM |

---

**建议学习路径**：

1. 📖 理解核心概念（Agent, Skill, Tool）
2. 🔧 动手实践（选一个框架做项目）
3. 🏗️ 学习架构（Memory, RAG, Orchestrator）
4. 🛡️ 关注安全（Guardrails, 权限控制）
5. 📈 持续跟进（新框架、新模型）

---

*本文基于 2025-2026 年 AI Agent 生态整理，欢迎交流讨论！*

**GitHub**: [linychuo](https://github.com/linychuo)  
**博客**: [yongchao.li](https://yongchao.li)
