# 006 - 技能与进化配置

> 详细介绍 OpenClaw 的技能管理、安全审查机制，以及通过 Memory/Soul 实现的代理进化。

## 什么是技能（Skill）

OpenClaw 的技能非常简单 —— **一个 Skill 就是一个文件夹，里面有一个 `SKILL.md` 文件**。不需要 SDK，不需要编译，不需要特殊运行时。

```
my-skill/
└── SKILL.md    # YAML frontmatter + Markdown 指令
```

`SKILL.md` 的结构：

```markdown
---
name: my-skill
description: 做某件事情
version: 1.0.0
requires:
  bins: [node, curl]          # 需要的系统工具
  permissions: [filesystem]   # 需要的权限
triggers:
  - "帮我做某事"              # 触发关键词
---

# 技能指令

当用户要求做某事时，按照以下步骤操作：

1. 首先检查...
2. 然后执行...
3. 最后确认...
```

## 技能来源

### 1. 内置技能（Bundled Skills）

OpenClaw 出厂自带一组基础技能。

### 2. ClawHub 社区技能

[ClawHub](https://clawhub.dev/) 是 OpenClaw 的官方技能市场，托管 3,200+ 技能。

```bash
# 搜索技能
openclaw skill search "calendar"

# 安装技能
openclaw skill install <skill-name>

# 列出已安装技能
openclaw skill list

# 卸载技能
openclaw skill uninstall <skill-name>
```

### 3. 本地自定义技能

```bash
# 自动生成技能模板
openclaw skill create my-custom-skill
```

生成的技能放在 `~/.openclaw/skills/` 或项目工作区中。

## 技能加载优先级

当同名技能存在冲突时，加载优先级为：

1. **工作区技能**（项目目录下的技能）— 最高优先级
2. **本地技能**（`~/.openclaw/skills/`）— 中间优先级
3. **内置技能**（bundled）— 最低优先级

## ⚠️ 技能安全：关键警告

> **安装 ClawHub 技能 = 在你的机器上执行第三方代码。**

这不是夸张。安全研究人员已发现的风险包括：

- **恶意软件分发**：VirusTotal 已检测到数百个包含后门、信息窃取器、远程访问工具的恶意技能
- **提示注入**：技能可以包含隐藏指令，操控代理行为
- **工具投毒**：看似正常的工具实际执行数据外泄
- **数据窃取**：Cisco 安全团队测试发现某第三方技能在用户不知情的情况下执行数据外泄和提示注入

### 安全审查流程

**安装任何技能之前，务必执行以下步骤：**

```bash
# 1. 查看技能的 VirusTotal 安全报告
# 在 ClawHub 上每个技能页面都有 VirusTotal 报告链接

# 2. 审查 SKILL.md 和所有脚本
cat ~/.openclaw/skills/<skill-name>/SKILL.md
# 仔细阅读每一行指令和脚本

# 3. 运行安全审计
openclaw security audit --fix

# 4. 首次运行使用沙箱
# 在 openclaw.json 中为该技能启用 Docker 沙箱
```

### 安全核查清单

```
□ 检查 SKILL.md 中是否有可疑的指令
□ 检查是否有隐藏的网络请求（数据外泄）
□ 检查是否有不必要的权限要求
□ 查看 ClawHub 上的 VirusTotal 报告
□ 查看社区评价和 star 数量
□ 首次运行在沙箱中测试
□ 开启 exec 审批功能直到信任该技能
```

### 安全工具

```bash
# 运行安全审计
openclaw security audit --fix

# 查看当前会话的有效沙箱和策略
openclaw sandbox explain
openclaw sandbox explain --session <session-id>
```

---

## Memory 与 Soul：代理进化机制

OpenClaw 最革命性的设计是将**所有认知状态存储为纯文本 Markdown 文件**。

### SOUL.md —— 代理的"灵魂"

每个 OpenClaw 代理都有一个 `SOUL.md` 文件，定义了代理是谁、如何行为、重视什么。

```markdown
# Soul

你是我的个人 AI 助手。

## 人格
- 简洁、高效、不废话
- 中文交流为主，技术术语保留英文
- 做事前先确认，不擅自决定

## 偏好
- 代码风格：函数式优先
- 沟通风格：直接、不要客套
- 时区：Asia/Shanghai

## 边界
- 不发送任何邮件（除非我明确要求）
- 不删除任何文件（除非我明确确认）
- 不进行任何支付操作
```

**每次代理启动时，它会首先读取 SOUL.md** —— 字面意义上"读自己进入存在"。

> **关键**：SOUL.md 是可写的。任何能修改 SOUL.md 的东西都能改变代理的身份。这既是强大之处，也是风险所在。

### MEMORY.md —— 长期记忆

```markdown
# Long-term Memory

## 项目
- Project Alpha: React + TypeScript，使用 Vite 构建
- 部署在 Vercel 上，域名 alpha.example.com

## 偏好（已验证）
- 用户喜欢用 pnpm 而不是 npm
- 用户习惯用 Neovim 编辑代码
- 每周五是 code review 日

## 教训
- 2026-02-15: 不要在周五下午部署到生产环境
- 2026-03-01: 用户的 NAS IP 是 192.168.1.100
```

### 每日日志 —— 短期记忆

```
~/.openclaw/memory/
├── 2026-03-09.md
├── 2026-03-10.md
└── 2026-03-11.md
```

每日日志是**追加式的临时记忆**，记录当天的上下文、决策和活动。

### 记忆持久化机制

当会话接近上下文窗口限制时，OpenClaw 会触发**预压缩记忆刷新**：

1. 系统检测到上下文即将被压缩
2. 触发一个静默的代理回合
3. 提醒模型将重要信息写入持久化文件
4. 然后才执行上下文压缩

这确保了即使原始对话历史被清除，关键信息已经被持久化到磁盘。

### 记忆搜索

OpenClaw 提供两个代理工具用于访问记忆文件：

| 工具 | 功能 |
|------|------|
| `memory_search` | 语义搜索 — 混合 BM25 + 向量搜索 |
| `memory_get` | 定向读取特定文件的指定行范围 |

搜索支持可选的 MMR 多样性和时间衰减（推荐半衰期 30 天）。

### 进化循环

```
日常琐碎 → memory/YYYY-MM-DD.md（短期记忆）
     ↓ 提炼
核心认知 → MEMORY.md（长期记忆）
     ↓ 内化
行为模式 → SOUL.md（灵魂/人格）
```

这模拟了人类从"写日记"到"形成世界观"的过程：

1. **每日日志**记录原始信息
2. 定期将有价值的信息提炼到 **MEMORY.md**
3. 深层行为偏好最终内化到 **SOUL.md**

### HEARTBEAT.md —— 心跳文件

```markdown
# Heartbeat

Last active: 2026-03-11T08:30:00+08:00
Session count: 147
Uptime: 45 days

## Current Focus
- Project Alpha 的 v2 重构

## Pending Tasks
- 回复张三的邮件
- 更新周报
```

> 核心原则：**如果没有写入文件，它就不存在。** 对话中的指令如果没有保存到文件，在上下文压缩后就会消失。

### ⚠️ 记忆安全风险

已知的"致命三角"：

1. **访问私密数据** + **暴露于不可信内容** + **能够执行外部通信并保留记忆**

真实案例：某安全研究员的代理在上下文压缩时丢失了"在我确认前不要做任何事"的指令（因为该指令在对话中给出，未保存到文件），代理恢复自主模式后开始删除邮件并忽略停止命令。

**防范措施**：

```bash
# 重要指令一定要写入 SOUL.md，不要只在对话中说
echo "## 绝对规则
- 永远不要自动删除任何内容
- 永远不要自动发送邮件" >> ~/.openclaw/agents/default/SOUL.md
```

## 推荐技能

### 内置技能（随 OpenClaw 发布）

| 技能 | 功能 | 来源 |
|------|------|------|
| `skill-creator` | 创建、编辑、改进和审查技能 | [openclaw/openclaw 内置](https://github.com/openclaw/openclaw/tree/main/skills/skill-creator) |

### 社区高质量技能（通过 ClawHub 安装）

以下是 2026 年下载量和社区评价最高的技能（来源：[Apiyi.com Top 10](https://help.apiyi.com/en/openclaw-skill-recommendations-2026-en.html)、[Composio Top 10](https://composio.dev/blog/top-openclaw-skills)）：

| 技能 | 功能 | 安装命令 |
|------|------|----------|
| `capability-evolver` | 代理能力进化引擎（35K+ 下载） | `clawhub install capability-evolver` |
| `openclaw-config-reference` | openclaw.json 配置参考和故障排查 | `clawhub install openclaw-config-reference` |
| `advanced-skill-creator` | 高级技能创建（5 步研究流程） | `clawhub install advanced-skill-creator` |
| `mission-control` | 日程和任务管理 | `clawhub install mission-control` |
| `tavily-search` | 网页搜索集成 | `clawhub install tavily-search` |
| `browser-relay` | 浏览器自动化 | `clawhub install browser-relay` |

> **⚠️ 即使是推荐技能，也建议先审查 SKILL.md 内容再启用。** ClawHub 注册表中约 20% 的技能存在安全风险（[Koi Security 2026 报告](https://nebius.com/blog/posts/openclaw-security)）。

## 下一步

进入 [007 - 安全沙箱配置](007-security-sandbox.md) 了解如何在本机安全运行 OpenClaw。

## 参考来源

- [OpenClaw 官方文档 - Skills](https://docs.openclaw.ai/tools/skills)
- [OpenClaw 官方文档 - Memory](https://docs.openclaw.ai/concepts/memory)
- [VoltAgent/awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills)
- [VirusTotal Blog - OpenClaw 技能被武器化](https://blog.virustotal.com/2026/02/from-automation-to-infection-how.html)
- [Medium - OpenClaw 与可编程灵魂](https://duncsand.medium.com/openclaw-and-the-programmable-soul-2546c9c1782c)
- [VelvetShark - OpenClaw 记忆大师课](https://velvetshark.com/openclaw-memory-masterclass)
- [Nebius - OpenClaw 安全架构和加固指南](https://nebius.com/blog/posts/openclaw-security)
- [LumaDock - 技能安全指南](https://lumadock.com/tutorials/openclaw-skills-guide)
