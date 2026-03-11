# OpenClaw 配置与应用完整指南

> 面向有编程经验、但未接触过 OpenClaw 或类似 AI 代理工具的开发者。

## 什么是 OpenClaw？

[OpenClaw](https://github.com/openclaw/openclaw)（曾用名 Clawdbot、Moltbot）是由 Peter Steinberger 开发的**开源自主 AI 代理**。它运行在本地，通过大语言模型执行任务，以即时通讯平台作为主要交互界面。

与传统聊天机器人不同，OpenClaw 是一个**真正的个人 AI 代理** —— 它可以记住上下文、操作你的文件系统、执行 Shell 命令、管理日历、收发邮件，甚至进行网页自动化操作。

**核心特点：**

- **模型无关**：支持 Anthropic Claude、OpenAI、Moonshot Kimi、本地模型等多种 LLM
- **多平台通讯**：通过 Telegram、WhatsApp、Signal、Discord、Slack 等平台交互
- **可扩展技能系统**：ClawHub 上有 3,200+ MCP 技能可供安装
- **持久化记忆**：通过 SOUL.md、MEMORY.md 等文件实现跨会话记忆
- **完全开源**：无需订阅，自带 API Key 即可使用

**项目状态**（截至 2026 年 3 月）：GitHub 247,000+ Stars，估计用户 30-40 万。

## 指南目录

| 章节 | 内容 | 难度 |
|------|------|------|
| [001 - macOS 安装指南](001-macos-installation.md) | Homebrew / npm / Docker 三种方式安装 | ⭐ |
| [002 - 基本配置与运行](002-basic-configuration.md) | openclaw.json 结构、目录布局、首次运行 | ⭐ |
| [003 - API 获取与配置](003-api-configuration.md) | Claude / Kimi / OpenRouter API 获取、充值、配置 | ⭐⭐ |
| [004 - 通讯软件配置](004-messaging-platforms.md) | Telegram / WhatsApp / Signal / Discord 等平台接入 | ⭐⭐ |
| [005 - 工具类软件配置](005-tool-integration.md) | 浏览器、日历、邮件、支付等 MCP 工具集成 | ⭐⭐⭐ |
| [006 - 技能与进化配置](006-skills-and-evolution.md) | 技能管理、安全审查、Memory/Soul 进化机制 | ⭐⭐⭐ |
| [007 - 安全沙箱配置](007-security-sandbox.md) | 本机运行的安全配置、沙箱隔离 | ⭐⭐⭐ |
| [008 - 组网与远程沙箱](008-remote-sandbox.md) | 绿联 NAS + macOS + Tailscale 远程部署 | ⭐⭐⭐⭐ |
| [009 - 故障排查与注意事项](009-troubleshooting.md) | 常见问题、排错流程、注意事项 | ⭐⭐ |
| [010 - 使用场景与用户旅程](010-usage-scenarios.md) | 实际案例：从日常助手到团队协作 | ⭐⭐ |

## 配套资源

- **[测试用例](../testcase/)**：每章对应的验证测试，帮助你确认配置是否正确
- **[便捷脚本](../scripts/)**：安装、诊断、备份等自动化脚本
- **[.claude/ 配置](../.claude/)**：内置的推荐技能和配置模板

## 前置要求

- macOS 12 (Monterey) 或更高版本
- 终端基本操作经验
- 至少一个 LLM API Key（详见 [003 章节](003-api-configuration.md)）
- （可选）Docker Desktop（用于沙箱模式）

## 参考来源

- [OpenClaw 官方文档](https://docs.openclaw.ai/)
- [OpenClaw GitHub 仓库](https://github.com/openclaw/openclaw)
- [ClawHub 技能市场](https://clawhub.dev/)
- [OpenClaw 安全指南（Nebius）](https://nebius.com/blog/posts/openclaw-security)
