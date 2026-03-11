# .claude/skills/ - 内置技能

本目录包含从真实开源仓库获取的推荐技能。

## 已包含的技能

### superpowers/（Claude Code 代理技能框架）

来源：[obra/superpowers](https://github.com/obra/superpowers)

**Superpowers 是一套完整的 AI 代理软件开发工作流**，由可组合的"技能"构成。它不仅适用于 Claude Code，也兼容 Codex、Gemini CLI、Cursor 等工具。

包含 14 个核心技能：

| 技能 | 功能 |
|------|------|
| `using-superpowers` | 核心引导 - 教代理如何查找和使用技能 |
| `brainstorming` | 创意工作前的需求探索和规格设计 |
| `writing-plans` | 多步骤任务的实施计划编写 |
| `executing-plans` | 按计划执行实施 |
| `test-driven-development` | TDD 红绿重构工作流 |
| `systematic-debugging` | 系统化调试方法论 |
| `verification-before-completion` | 完成前的验证检查 |
| `writing-skills` | 创建和编辑技能 |
| `dispatching-parallel-agents` | 并行子代理调度 |
| `subagent-driven-development` | 子代理驱动开发 |
| `using-git-worktrees` | Git Worktree 隔离开发 |
| `finishing-a-development-branch` | 开发分支收尾流程 |
| `requesting-code-review` | 发起代码审查 |
| `receiving-code-review` | 处理代码审查反馈 |

许可证：MIT

### skill-creator/（OpenClaw 官方内置技能）

来源：[openclaw/openclaw/skills/skill-creator](https://github.com/openclaw/openclaw/tree/main/skills/skill-creator)

功能：创建、编辑、改进和审查 OpenClaw 技能。提供完整的技能开发工作流：
- `scripts/init_skill.py` - 初始化新技能目录
- `scripts/package_skill.py` - 打包技能为 .skill 文件
- `scripts/quick_validate.py` - 验证技能格式

许可证：Apache License 2.0

## 推荐安装的社区技能

以下技能需要通过 `clawhub install` 命令从 [ClawHub](https://clawhub.dev/) 安装：

```bash
# 配置参考（官方出品）
clawhub install openclaw-config-reference

# 高级技能创建器（社区精品）
clawhub install advanced-skill-creator
```

### 2026 年 Top 10 推荐 OpenClaw 技能

| 技能 | 功能 | 安装命令 |
|------|------|----------|
| openclaw-config-reference | openclaw.json 配置参考和故障排查 | `clawhub install openclaw-config-reference` |
| advanced-skill-creator | 高级技能创建（5 步研究流程） | `clawhub install advanced-skill-creator` |
| capability-evolver | 代理能力进化引擎（35K+ 下载） | `clawhub install capability-evolver` |
| mission-control | 日程和任务管理 | `clawhub install mission-control` |
| tavily-search | 网页搜索集成 | `clawhub install tavily-search` |
| browser-relay | 浏览器自动化 | `clawhub install browser-relay` |
| github | GitHub 代码管理 | `clawhub install github` |
| eleven-labs-agent | 语音交互 | `clawhub install eleven-labs-agent` |
| summarize | 内容摘要生成 | `clawhub install summarize` |
| n8n-workflow | N8N 工作流自动化 | `clawhub install n8n-workflow` |

> **来源**：[Apiyi.com - 2026 年 OpenClaw 技能推荐](https://help.apiyi.com/en/openclaw-skill-recommendations-2026-en.html)

### 推荐的 Claude Code 技能资源

| 资源 | 说明 |
|------|------|
| [obra/superpowers-skills](https://github.com/obra/superpowers-skills) | Superpowers 社区技能（可编辑） |
| [obra/superpowers-lab](https://github.com/obra/superpowers-lab) | Superpowers 实验性技能 |
| [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) | Claude Skills 精选列表 |
| [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | 500+ 跨平台代理技能 |

## ⚠️ 安全提醒

**安装任何社区技能前必须审查**：

1. 在 ClawHub 上检查 VirusTotal 安全报告
2. 阅读完整的 SKILL.md 内容
3. 检查 scripts/ 中的每个脚本
4. 首次运行使用沙箱模式
5. 运行 `openclaw security audit --fix`

ClawHub 注册表中约 20% 的技能存在安全风险（来源：Koi Security 2026 年报告）。

## 参考来源

- [obra/superpowers GitHub](https://github.com/obra/superpowers)
- [OpenClaw 官方技能文档](https://docs.openclaw.ai/tools/skills)
- [ClawHub 官方注册表](https://clawhub.dev/)
- [VoltAgent/awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills) - 5,400+ 精选 OpenClaw 技能
- [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) - Claude Skills 精选列表
- [Composio - Top 10 OpenClaw Skills](https://composio.dev/blog/top-openclaw-skills)
