---
title: "AI Agent Skills 术语详解：2025-2026 完整指南（进阶版）"
date_time: 2026-03-08 17:45:00
tags: AI Agent Skills MCP LLM 人工智能
---

# AI Agent Skills 术语详解：2025-2026 完整指南（进阶版）

> 本文系统整理了 AI Agent 生态中的核心术语、架构组件和新兴标准，配合图解帮助你深入理解这个快速发展的领域。

---

## 一、核心概念全景图

```mermaid
graph TB
    User[用户] --> Agent[AI Agent]
    Agent --> LLM[大语言模型]
    Agent --> Memory[记忆系统]
    Agent --> Tools[工具集]
    
    Tools --> Skill[Skills]
    Tools --> MCP[MCP Protocol]
    Tools --> API[外部 API]
    
    LLM --> FunctionCall[Function Calling]
    FunctionCall --> Tools
    
    Memory --> ShortTerm[短期记忆]
    Memory --> LongTerm[长期记忆]
    
    Agent --> Output[输出/行动]
```

---

## 二、基础术语

### 1. AI Agent（智能体）

**定义**：能够感知环境、做出决策并执行动作的 AI 系统。

**核心能力**：
- 🧠 **推理** - 理解任务、规划步骤
- 🔧 **工具使用** - 调用外部 API、执行代码
- 💬 **对话** - 与用户自然交互
- 🔄 **记忆** - 保留上下文和历史

**Agent 工作循环**：

```mermaid
graph LR
    A[感知输入] --> B[理解意图]
    B --> C[规划步骤]
    C --> D[选择工具]
    D --> E[执行动作]
    E --> F[观察结果]
    F --> G{任务完成？}
    G -->|否 | C
    G -->|是 | H[输出结果]
```

**示例**：
```
用户：帮我查下北京天气，然后写封邮件给团队

Agent 执行流程：
1. 解析意图 → 查天气 + 写邮件
2. 调用天气 API → 获取北京当前温度
3. 撰写邮件草稿 → 包含天气信息
4. 请求用户确认 → 等待批准
5. 调用邮件 API → 发送邮件
6. 返回确认 → 任务完成
```

---

### 2. Skill / Tool / Capability（技能/工具/能力）

这三个词经常混用，但有细微差别：

| 术语 | 含义 | 粒度 | 示例 |
|------|------|------|------|
| **Capability** | 抽象能力描述 | 最粗 | "能联网"、"能执行代码" |
| **Skill** | 高级能力，可能包含多个工具 | 中等 | "搜索技能"、"写作技能" |
| **Tool** | 具体可执行的函数/API | 最细 | `web_search()`, `send_email()` |

**层级关系**：

```mermaid
graph TD
    Cap[Capability: 信息获取] --> Skill1[Skill: 网络搜索]
    Cap --> Skill2[Skill: 文件读取]
    
    Skill1 --> Tool1[Tool: web_search]
    Skill1 --> Tool2[Tool: web_fetch]
    
    Skill2 --> Tool3[Tool: read_file]
    Skill2 --> Tool4[Tool: list_dir]
```

**技能结构示例**：
```yaml
skill: github
description: 管理 GitHub 仓库
capability: 代码协作
tools:
  - name: gh_issue_create
    description: 创建 Issue
  - name: gh_pr_review
    description: 审查 PR
  - name: gh_run_list
    description: 查看 CI 运行
config:
  - GITHUB_TOKEN
```

---

### 3. Function Calling（函数调用）

**定义**：LLM 识别用户意图后，调用外部函数获取结果。

**工作流程**：

```mermaid
sequenceDiagram
    participant U as 用户
    participant L as LLM
    participant F as 函数执行器
    participant E as 外部服务
    
    U->>L: 北京今天天气如何？
    L->>L: 分析意图，选择函数
    L->>F: get_weather(location="Beijing")
    F->>E: 调用天气 API
    E->>F: 返回天气数据
    F->>L: 返回结果
    L->>U: 北京今天晴，25°C
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

// 函数返回结果
{
  "temperature": 25,
  "condition": "sunny",
  "humidity": 45
}
```

---

## 三、架构组件

### 4. Orchestrator（编排器）

**定义**：协调多个 Agent 或工具完成复杂任务的中央控制器。

**职责**：
- 📋 任务分解
- 🎯 分配子任务给不同 Agent
- 🔗 整合结果
- ⚠️ 错误处理

**编排模式对比**：

| 模式 | 适用场景 | 优点 | 缺点 |
|------|----------|------|------|
| **集中式** | 简单任务 | 控制清晰 | 单点故障 |
| **分布式** | 复杂任务 | 灵活扩展 | 协调困难 |
| **混合式** | 中等复杂度 | 平衡灵活与控制 | 设计复杂 |

**示例架构**：

```mermaid
graph TB
    User[用户请求] --> Orch[Orchestrator]
    Orch --> Parse[任务解析]
    Parse --> Plan[生成计划]
    Plan --> Assign[分配任务]
    
    Assign --> Agent1[Search Agent]
    Assign --> Agent2[Code Agent]
    Assign --> Agent3[Write Agent]
    
    Agent1 --> Result1[搜索结果]
    Agent2 --> Result2[代码实现]
    Agent3 --> Result3[文档撰写]
    
    Result1 --> Merge[结果整合]
    Result2 --> Merge
    Result3 --> Merge
    
    Merge --> Output[返回用户]
```

---

### 5. Memory System（记忆系统）

**定义**：让 Agent 记住历史对话和上下文信息的机制。

**三层记忆架构**：

```mermaid
graph TB
    subgraph Memory System
        WM[工作记忆<br/>Working Memory]
        STM[短期记忆<br/>Short-term Memory]
        LTM[长期记忆<br/>Long-term Memory]
    end
    
    Input[输入] --> WM
    WM --> STM
    STM -->|重要信息 | LTM
    LTM -->|检索 | WM
    
    WM --> Agent[Agent 决策]
```

**记忆类型详解**：

| 类型 | 持续时间 | 容量 | 实现方式 | 示例 |
|------|----------|------|----------|------|
| **工作记忆** | 当前任务 | 有限 | 变量、状态机 | 当前处理的文件列表 |
| **短期记忆** | 当前会话 | Token 窗口 | 对话历史 | 本次聊天的所有内容 |
| **长期记忆** | 跨会话 | 理论上无限 | 向量数据库、文件 | 用户偏好、项目信息 |

**nanobot 记忆架构**：
```
memory/
├── MEMORY.md          # 长期事实（用户信息、偏好）
├── HISTORY.md         # 事件日志（可 grep 搜索）
└── sessions/          # 会话记录（按日期分文件）
    ├── 2026-03-08.md
    └── 2026-03-07.md
```

---

### 6. Context Window（上下文窗口）

**定义**：LLM 一次能处理的 token 数量限制。

**常见模型对比**：

| 模型 | 上下文窗口 | 约等于 | 适合场景 |
|------|-----------|--------|----------|
| GPT-4 Turbo | 128K | 96,000 汉字 | 长文档分析 |
| Claude-3 Opus | 200K | 150,000 汉字 | 整本书分析 |
| Llama-3 | 128K | 96,000 汉字 | 开源部署 |
| Gemini-1.5 | 1M+ | 750,000 汉字 | 超长上下文 |

**上下文管理策略**：

```mermaid
graph LR
    A[完整对话] --> B{是否超出限制？}
    B -->|否 | C[直接使用]
    B -->|是 | D[压缩策略]
    
    D --> D1[摘要压缩]
    D --> D2[删除早期对话]
    D --> D3[RAG 检索]
    D --> D4[分层存储]
    
    D1 --> E[优化后的上下文]
    D2 --> E
    D3 --> E
    D4 --> E
```

---

## 四、关键技术

### 7. RAG（Retrieval-Augmented Generation）

**定义**：检索增强生成，先从知识库检索信息，再让 LLM 生成回答。

**完整流程**：

```mermaid
graph TB
    subgraph 索引阶段
        Doc[文档] --> Chunk[分块]
        Chunk --> Embed[向量化]
        Embed --> DB[(向量数据库)]
    end
    
    subgraph 查询阶段
        Query[用户问题] --> QEmbed[向量化]
        QEmbed --> Search[相似度搜索]
        Search --> DB
        DB --> Results[相关文档]
        Results --> Prompt[构建 Prompt]
        Prompt --> LLM[LLM 生成]
        LLM --> Answer[回答]
    end
```

**应用场景**：
- 📚 企业知识库问答
- 📄 长文档分析
- 🔍 需要最新信息的场景
- 🏥 医疗/法律等专业领域

**RAG vs Fine-tuning**：

| 维度 | RAG | Fine-tuning |
|------|-----|-------------|
| **数据更新** | 实时更新 | 需重新训练 |
| **成本** | 低 | 高 |
| **准确性** | 依赖检索质量 | 依赖训练数据 |
| **适用场景** | 知识问答 | 风格/任务适配 |

---

### 8. Prompt Engineering（提示工程）

**定义**：设计有效的 Prompt 来引导 LLM 输出期望结果。

**核心技巧**：

| 技巧 | 说明 | 示例 |
|------|------|------|
| **Zero-Shot** | 直接提问 | "翻译这句话" |
| **Few-Shot** | 提供示例 | "例如：... 例如：... 现在请..." |
| **Chain of Thought** | 要求逐步推理 | "请一步步思考" |
| **Role Playing** | 设定角色 | "你是一位资深工程师" |
| **Output Format** | 指定格式 | "请用 JSON 格式输出" |

**Prompt 结构模板**：

```markdown
# Role
你是一位 [角色]，擅长 [技能]

# Context
[背景信息]

# Task
[具体任务]

# Constraints
- [限制 1]
- [限制 2]

# Output Format
[期望的输出格式]

# Examples
[示例输入输出]
```

---

### 9. Agent Framework（Agent 框架）

**定义**：构建 Agent 应用的开发框架。

**主流框架对比**：

| 框架 | 语言 | 核心特点 | 适合场景 |
|------|------|----------|----------|
| **LangChain** | Python/JS | 生态最丰富，组件多 | 通用 Agent 开发 |
| **LlamaIndex** | Python | RAG 专精，数据连接强 | 知识库问答 |
| **AutoGen** | Python | 多 Agent 协作 | 复杂任务分解 |
| **CrewAI** | Python | 角色分工，流程清晰 | 团队协作模拟 |
| **Semantic Kernel** | C#/Python | 微软出品，.NET 友好 | 企业应用 |
| **Haystack** | Python | 搜索管道，NLP 专注 | 搜索问答系统 |

**框架选择指南**：

```mermaid
graph TD
    Start[开始选择] --> Need{需求类型？}
    
    Need -->|RAG/知识库 | Llama[LlamaIndex]
    Need -->|多 Agent 协作 | AutoGen[AutoGen/CrewAI]
    Need -->|通用开发 | LangChain[LangChain]
    Need -->|.NET 生态 | SK[Semantic Kernel]
    Need -->|搜索/NLP | Haystack[Haystack]
    
    Llama --> End[开始开发]
    AutoGen --> End
    LangChain --> End
    SK --> End
    Haystack --> End
```

---

## 五、新兴标准

### 10. MCP（Model Context Protocol）⭐

**定义**：由 Anthropic 提出的开放协议，用于标准化 LLM 与外部工具/数据的连接。

**官网**：https://modelcontextprotocol.io

**核心价值**：
- 🔌 **统一接口** - 所有工具使用相同协议
- 🔒 **安全可控** - 明确的权限和范围
- 🔗 **互操作性** - 不同 Agent 可共享工具

**MCP 架构**：

```mermaid
graph TB
    Host[Host 应用<br/>如 Claude Desktop] <--> MCP[MCP Protocol]
    MCP <--> Server[MCP Server]
    Server --> Resources[资源<br/>文件/数据库]
    Server --> Tools[工具<br/>API/命令]
    Server --> Prompts[Prompt 模板]
```

**MCP 三大核心概念**：

| 概念 | 说明 | 示例 |
|------|------|------|
| **Resources** | 只读数据源 | 文件、数据库记录、API 响应 |
| **Tools** | 可执行操作 | 运行命令、调用 API、修改数据 |
| **Prompts** | 预定义模板 | 代码审查、文档生成模板 |

**MCP Server 示例**：

```json
// MCP Server 配置
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"],
      "args": ["/home/user/documents"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "..."
      }
    }
  }
}
```

**MCP vs 传统 Tool Calling**：

| 维度 | 传统方式 | MCP |
|------|----------|-----|
| **接口** | 各框架自定义 | 统一协议 |
| **发现** | 硬编码 | 动态发现 |
| **安全** | 框架级别 | 协议级别 |
| **复用** | 困难 | 容易 |

---

### 11. A2A（Agent-to-Agent Protocol）

**定义**：Agent 之间通信的标准化协议。

**核心能力**：
- 📤 **任务委托** - Agent A 将子任务交给 Agent B
- 🔄 **状态同步** - 共享任务进度
- 📋 **结果返回** - 结构化返回执行结果

**通信模式**：

```mermaid
sequenceDiagram
    participant M as Manager Agent
    participant W as Worker Agent
    participant R as Resource Agent
    
    M->>W: 执行代码生成任务
    W->>R: 请求代码模板
    R->>W: 返回模板
    W->>W: 生成代码
    W->>M: 返回结果
    M->>M: 整合所有结果
```

---

### 12. Local LLM（本地大模型）

**定义**：在本地设备运行的大语言模型。

**优势**：
- 🔒 数据隐私
- 💰 无 API 费用
- 🌐 离线可用
- ⚡ 低延迟

**挑战**：
- 💻 硬件要求高
- ⚡ 推理速度慢
- 📉 模型质量可能较低

**流行方案对比**：

| 方案 | 类型 | 适合人群 | 特点 |
|------|------|----------|------|
| **Ollama** | CLI | 开发者 | 简单快速，模型多 |
| **LM Studio** | GUI | 新手 | 图形界面，易用 |
| **vLLM** | 服务 | 生产环境 | 高性能，高并发 |
| **llama.cpp** | 库 | 嵌入式 | 轻量，跨平台 |

**安装示例**：
```bash
# Ollama
curl -fsSL https://ollama.com/install.sh | sh
ollama run llama3

# LM Studio
# 下载安装包，图形界面操作

# vLLM
pip install vllm
python -m vllm.entrypoints.api_server --model meta-llama/Llama-2-7b
```

---

### 13. Model Gateway（模型网关）

**定义**：统一管理多个 LLM API 的中间层。

**核心功能**：

```mermaid
graph TB
    App[应用程序] --> Gateway[Model Gateway]
    
    Gateway --> Route[路由模块]
    Gateway --> Cache[缓存模块]
    Gateway --> Rate[限流模块]
    Gateway --> Cost[成本模块]
    
    Route --> API1[OpenAI API]
    Route --> API2[Anthropic API]
    Route --> API3[本地模型]
    
    Cache --> DB[(响应缓存)]
    Cost --> Log[(使用日志)]
```

**功能详解**：

| 功能 | 说明 | 价值 |
|------|------|------|
| **模型路由** | 根据任务自动选择模型 | 成本优化 |
| **请求缓存** | 缓存相似请求的响应 | 降低延迟和成本 |
| **限流保护** | 防止 API 超限 | 稳定性 |
| **成本统计** | 追踪各模型使用量 | 预算管理 |
| **故障转移** | API 失败时自动切换 | 高可用 |

**示例配置**：
```yaml
gateway:
  models:
    - name: gpt-4
      endpoint: https://api.openai.com
      cost: $0.03/1K
      priority: 1
    - name: claude-3
      endpoint: https://api.anthropic.com
      cost: $0.025/1K
      priority: 2
    - name: llama-3-local
      endpoint: http://localhost:8000
      cost: $0
      priority: 3
  
  routing:
    strategy: cost_optimized
    fallback: true
  
  cache:
    enabled: true
    ttl: 3600
```

---

### 14. Skill Registry（技能注册中心）

**定义**：集中管理和分发 Agent 技能的平台。

**主要平台**：

| 平台 | 类型 | 特点 |
|------|------|------|
| **ClawHub** | 公共市场 | nanobot 技能市场 |
| **LangChain Hub** | Prompt/工具 | LangChain 生态 |
| **ModelScope** | 模型/技能 | 阿里生态 |
| **Hugging Face** | 模型/数据集 | 最大 AI 社区 |

**技能包结构**：
```
skill-name/
├── SKILL.md             # 技能说明文档
├── tools/               # 工具实现
│   ├── __init__.py
│   └── main.py
├── config.yaml          # 配置定义
├── requirements.txt     # Python 依赖
└── tests/               # 测试用例
```

**技能发现流程**：

```mermaid
graph LR
    A[用户搜索] --> B[技能注册中心]
    B --> C[返回技能列表]
    C --> D[查看详情]
    D --> E[安装技能]
    E --> F[配置凭证]
    F --> G[技能可用]
```

---

## 六、安全与治理

### 15. Guardrails（护栏）

**定义**：限制 Agent 行为的安全机制。

**多层防护体系**：

```mermaid
graph TB
    subgraph 输入层
        Input[用户输入] --> Filter1[恶意 Prompt 检测]
        Filter1 --> Filter2[敏感词过滤]
    end
    
    subgraph 执行层
        Filter2 --> Auth[权限验证]
        Auth --> Limit[速率限制]
        Limit --> Sandbox[沙箱执行]
    end
    
    subgraph 输出层
        Sandbox --> Review1[内容审查]
        Review1 --> Review2[事实核查]
        Review2 --> Output[最终输出]
    end
```

**护栏类型**：

| 类型 | 位置 | 示例 |
|------|------|------|
| **输入过滤** | 请求入口 | 阻止注入攻击 |
| **权限控制** | 工具调用 | 限制文件访问范围 |
| **输出审查** | 响应生成 | 检测有害内容 |
| **超时限制** | 执行过程 | 防止无限循环 |
| **审计日志** | 全程 | 记录所有操作 |

**代码示例**：
```python
# 危险命令拦截
DANGEROUS_COMMANDS = ["rm -rf /", "dd", "format", "shutdown"]

def execute_command(command: str):
    if any(cmd in command for cmd in DANGEROUS_COMMANDS):
        raise SecurityError("Dangerous command blocked")
    
    # 沙箱执行
    with sandbox():
        return subprocess.run(command, capture_output=True)
```

---

### 16. Human-in-the-Loop（人在回路）

**定义**：关键决策需要人工确认。

**触发场景**：

| 场景 | 风险等级 | 确认方式 |
|------|----------|----------|
| 资金操作 | 🔴 高 | 必须确认 |
| 发送邮件/消息 | 🟡 中 | 建议确认 |
| 执行危险命令 | 🔴 高 | 必须确认 |
| 发布内容 | 🟡 中 | 建议确认 |
| 数据修改 | 🟡 中 | 建议确认 |
| 信息查询 | 🟢 低 | 无需确认 |

**实现模式**：

```mermaid
sequenceDiagram
    participant U as 用户
    participant A as Agent
    participant H as Human
    
    A->>A: 分析任务
    A->>A{需要确认？}
    A->>H|是 | 请求确认
    H->>A: 批准/拒绝
    A->>A{批准？}
    A->>A|是 | 执行操作
    A->>A|否 | 取消任务
    A->>U: 返回结果
```

---

## 七、评估与监控

### 17. Agent Evaluation（Agent 评估）

**评估维度**：

| 维度 | 指标 | 计算方法 | 目标值 |
|------|------|----------|--------|
| **准确性** | Task Success Rate | 成功任务数/总任务数 | >90% |
| **效率** | Steps to Complete | 平均完成步数 | 越少越好 |
| **成本** | Token Usage | 每次任务平均 Token | 根据预算 |
| **安全性** | Violation Rate | 违规次数/总操作数 | 0% |
| **延迟** | Response Time | 平均响应时间 | <5s |

**评估流程**：

```mermaid
graph TB
    TestSet[测试用例集] --> Run[执行测试]
    Run --> Collect[收集指标]
    Collect --> Analyze[分析结果]
    Analyze --> Report[生成报告]
    Report --> Improve[改进优化]
    Improve --> Run
```

---

### 18. Observability（可观测性）

**定义**：监控和追踪 Agent 行为的能力。

**关键数据**：

```mermaid
graph LR
    subgraph 可观测性数据
        Logs[日志<br/>完整对话记录]
        Traces[追踪<br/>工具调用链]
        Metrics[指标<br/>性能/成本]
    end
    
    Logs --> Dashboard[监控面板]
    Traces --> Dashboard
    Metrics --> Dashboard
    
    Dashboard --> Alert[告警]
    Dashboard --> Report[报告]
```

**主流工具**：

| 工具 | 特点 | 适合场景 |
|------|------|----------|
| **LangSmith** | LangChain 官方 | LangChain 项目 |
| **Arize Phoenix** | 开源，LLM 专注 | 生产环境 |
| **Helicone** | 开源，自托管 | 数据敏感场景 |
| **Weights & Biases** | 实验追踪 | 模型开发 |

---

## 八、新兴趋势

### 19. Multi-Agent Systems（多 Agent 系统）

**定义**：多个 Agent 协作完成复杂任务。

**协作模式**：

```mermaid
graph TB
    subgraph 主从模式
        Manager[Manager Agent] --> Worker1[Worker 1]
        Manager --> Worker2[Worker 2]
        Manager --> Worker3[Worker 3]
    end
    
    subgraph 对等模式
        Peer1[Peer 1] <--> Peer2[Peer 2]
        Peer2 <--> Peer3[Peer 3]
        Peer1 <--> Peer3
    end
    
    subgraph 流水线模式
        Stage1[阶段 1] --> Stage2[阶段 2]
        Stage2 --> Stage3[阶段 3]
    end
```

**模式对比**：

| 模式 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **主从模式** | 控制清晰，易于调试 | 单点瓶颈 | 任务明确的项目 |
| **对等模式** | 灵活，容错性好 | 协调复杂 | 探索性任务 |
| **流水线模式** | 流程清晰，可并行 | 灵活性低 | 标准化流程 |

**示例场景**：

```
任务：开发一个待办事项 Web 应用

Product Agent → 需求文档 + 用户故事
    ↓
Architect Agent → 技术选型 + 架构设计
    ↓
Code Agent → 实现代码
    ↓
Test Agent → 单元测试 + 集成测试
    ↓
Deploy Agent → 部署上线
```

---

### 20. Agentic Workflow（Agent 工作流）

**定义**：将 Agent 集成到业务流程中。

**典型场景**：

| 场景 | 自动化程度 | ROI |
|------|------------|-----|
| 📧 客户邮件处理 | 80% | 高 |
| 📊 日报/周报生成 | 90% | 中 |
| 🔍 竞品监控 | 70% | 高 |
| 💬 客服支持 | 60% | 高 |
| 📝 内容创作 | 50% | 中 |

**工作流设计**：

```mermaid
graph TB
    Trigger[触发事件] --> Classify[分类路由]
    Classify --> Simple{简单任务？}
    Simple -->|是 | Auto[自动处理]
    Simple -->|否 | Agent[Agent 处理]
    
    Agent --> Review{需要审核？}
    Review -->|是 | Human[人工审核]
    Review -->|否 | Execute[执行]
    
    Human --> Execute
    Auto --> Log[记录日志]
    Execute --> Log
```

---

### 21. Small Language Models（小语言模型）

**定义**：参数量较小（<10B）但针对特定任务优化的模型。

**代表模型**：

| 模型 | 参数量 | 特点 | 适用场景 |
|------|--------|------|----------|
| **Phi-3** | 3.8B | 微软出品，性能强 | 通用任务 |
| **Gemma-2B** | 2B | Google 开源 | 轻量应用 |
| **Qwen-1.8B** | 1.8B | 阿里出品，中文好 | 中文场景 |
| **TinyLlama** | 1.1B | 极轻量 | 边缘设备 |

**选型指南**：

```mermaid
graph TD
    Start[选择模型] --> Hardware{硬件条件？}
    
    Hardware -->|GPU 8GB+ | Medium[7B 模型]
    Hardware -->|GPU 4GB | Small[3B 模型]
    Hardware -->|CPU only | Tiny[1B 模型]
    
    Medium --> Task{任务类型？}
    Small --> Task
    Tiny --> Task
    
    Task -->|通用对话 | Phi3[Phi-3]
    Task -->|中文场景 | Qwen[Qwen]
    Task -->|代码生成 | StarCoder[StarCoder]
```

---

## 九、nanobot 实践案例

### 我的技能架构

```
nanobot 🐈
├── 核心技能（内置）
│   ├── memory - 两层记忆系统
│   ├── cron - 定时提醒
│   ├── weather - 天气查询
│   ├── tmux - 终端会话管理
│   └── skill-creator - 技能开发
├── 工具能力
│   ├── 文件操作 (read/write/edit_file)
│   ├── 目录操作 (list_dir)
│   ├── 命令执行 (exec)
│   └── 网络访问 (web_search/web_fetch)
└── 扩展技能（ClawHub）
    ├── github - GitHub CLI 集成
    └── 更多技能...
```

### 技能开发规范

```markdown
# SKILL.md 标准结构

## 功能描述
技能能做什么，解决什么问题

## 工具列表
- tool_name - 功能说明 - 参数

## 配置要求
- API_KEY - 说明 - 获取方式

## 使用示例
```bash
command example
```

## 依赖
- 需要安装的 CLI 工具
- Python 包
```

### MCP 兼容性计划

nanobot 正在考虑支持 MCP 协议：

```yaml
# 未来可能的 MCP 配置
mcpServers:
  nanobot:
    command: nanobot
    args: ["--mcp-server"]
    capabilities:
      - memory
      - cron
      - weather
      - file_operations
```

---

## 十、术语关系总览

### 完整架构图

```mermaid
graph TB
    subgraph 用户层
        User[用户]
        UI[交互界面]
    end
    
    subgraph Agent 层
        Agent[AI Agent]
        Orch[Orchestrator]
    end
    
    subgraph 核心层
        LLM[大语言模型]
        Memory[记忆系统]
        FC[Function Calling]
    end
    
    subgraph 工具层
        Skills[Skills]
        MCP[MCP Protocol]
        Tools[Tools]
    end
    
    subgraph 外部层
        API[外部 API]
        DB[数据库]
        FS[文件系统]
    end
    
    User --> UI
    UI --> Agent
    Agent --> Orch
    Orch --> LLM
    Orch --> Memory
    LLM --> FC
    FC --> Skills
    Skills --> MCP
    MCP --> Tools
    Tools --> API
    Tools --> DB
    Tools --> FS
    
    Memory -.-> LLM
    API -.-> LLM
```

### 术语分类表

| 类别 | 术语 | 重要性 |
|------|------|--------|
| **核心概念** | Agent, Skill, Tool, Function Calling | ⭐⭐⭐ |
| **架构组件** | Orchestrator, Memory, Context Window | ⭐⭐⭐ |
| **关键技术** | RAG, Prompt Engineering, Framework | ⭐⭐⭐ |
| **新兴标准** | MCP, A2A Protocol | ⭐⭐ |
| **部署运行** | Local LLM, Model Gateway, Skill Registry | ⭐⭐ |
| **安全治理** | Guardrails, Human-in-the-Loop | ⭐⭐⭐ |
| **评估监控** | Evaluation, Observability | ⭐⭐ |
| **发展趋势** | Multi-Agent, Agentic Workflow, SLM | ⭐⭐ |

---

## 总结

AI Agent 生态正在快速发展，本文整理了 21 个核心术语：

| 学习阶段 | 术语 |
|----------|------|
| **入门** | Agent, Skill, Tool, Function Calling, Prompt |
| **进阶** | RAG, Memory, Orchestrator, Framework |
| **高级** | MCP, Multi-Agent, Guardrails, Observability |

---

**建议学习路径**：

```mermaid
graph LR
    A[阶段 1: 基础概念] --> B[阶段 2: 动手实践]
    B --> C[阶段 3: 架构设计]
    C --> D[阶段 4: 安全治理]
    D --> E[阶段 5: 持续跟进]
    
    A --> A1[Agent, Skill, Tool]
    B --> B1[选框架做项目]
    C --> C1[Memory, RAG, MCP]
    D --> D1[Guardrails, 评估]
    E --> E1[新模型，新标准]
```

---

**推荐资源**：

| 类型 | 资源 |
|------|------|
| 📚 文档 | [LangChain Docs](https://python.langchain.com), [MCP Spec](https://modelcontextprotocol.io) |
| 🎥 视频 | YouTube: LangChain, Anthropic |
| 💻 实践 | 用 nanobot 创建自己的 Skill |
| 📰 资讯 | Hacker News AI, Twitter AI 社区 |

---

*本文基于 2025-2026 年 AI Agent 生态整理，将持续更新。*

**GitHub**: [linychuo](https://github.com/linychuo)  
**博客**: [yongchao.li](https://yongchao.li)  
**Telegram**: @nanobot
