# OC Guide

OpenClaw AI 代理的中文配置与使用指南仓库，面向有编程经验但未接触过 OpenClaw 或类似 AI 代理工具的开发者。

## 什么是 OpenClaw？

[OpenClaw](https://github.com/openclaw/openclaw) 是一个开源的自主 AI 代理框架，运行在本地，通过大语言模型执行任务，以即时通讯平台作为主要交互界面。它不是聊天机器人，而是一个能记住上下文、操作文件系统、执行 Shell 命令、管理日历、收发邮件、进行网页自动化的个人 AI 代理。

**核心特点：**
- **模型无关**：支持 Anthropic Claude、OpenAI、Moonshot Kimi、本地模型等多种 LLM
- **多平台通讯**：通过 Telegram、WhatsApp、Signal、Discord、Slack 等平台交互
- **可扩展技能系统**：ClawHub 上有 3,200+ MCP 技能可供安装
- **持久化记忆**：通过 SOUL.md、MEMORY.md 等文件实现跨会话记忆
- **完全开源**：无需订阅，自带 API Key 即可使用

---

## 项目结构

```
oc-guide/
├── README.md
├── LICENSE
├── guide/                          # 配置与使用指南（10 章 + 国产替代方案）
│   ├── index.md                    # 指南总目录与导读
│   ├── 001-macos-installation.md
│   ├── 002-basic-configuration.md
│   ├── 003-api-configuration.md
│   ├── 004-messaging-platforms.md
│   ├── 005-tool-integration.md
│   ├── 006-skills-and-evolution.md
│   ├── 007-security-sandbox.md
│   ├── 008-remote-sandbox.md
│   ├── 009-troubleshooting.md
│   ├── 010-usage-scenarios.md
│   └── openclaw-alternatives/      # 国内 OpenClaw 类产品对比与选型
│       ├── README.md               # 总览、对比表与选型建议
│       ├── tencent-workbuddy-qclaw.md
│       ├── alibaba-copaw-qoderwork.md
│       ├── bytedance-coze-openclaw.md
│       ├── moonshot-kimiclaw.md
│       ├── netease-lobsterai.md
│       ├── xiaomi-miclaw.md
│       └── baidu-qianfan-openclaw.md
├── testcase/                       # 每章对应的验证测试用例
│   ├── 001-macos-installation.md
│   ├── 002-basic-configuration.md
│   └── ...（共 10 个）
└── scripts/                        # 安装、备份、健康检查脚本
    ├── README.md
    ├── install.sh
    ├── backup.sh
    └── health-check.sh
```

---

## guide/ — 配置与使用指南

包含 10 章循序渐进的中文指南，从安装到高级部署完整覆盖 OpenClaw 的使用流程。

| 章节 | 内容 | 难度 |
|------|------|------|
| [001 - macOS 安装](guide/001-macos-installation.md) | Homebrew / npm / Docker 三种安装方式 | ⭐ |
| [002 - 基本配置与运行](guide/002-basic-configuration.md) | openclaw.json 结构、目录布局、首次运行 | ⭐ |
| [003 - API 获取与配置](guide/003-api-configuration.md) | Claude / Kimi / OpenRouter API 获取、充值、配置 | ⭐⭐ |
| [004 - 通讯软件配置](guide/004-messaging-platforms.md) | Telegram / WhatsApp / Signal / Discord 等平台接入 | ⭐⭐ |
| [005 - 工具类软件配置](guide/005-tool-integration.md) | 浏览器、日历、邮件、支付等 MCP 工具集成 | ⭐⭐⭐ |
| [006 - 技能与进化配置](guide/006-skills-and-evolution.md) | 技能管理、安全审查、Memory/Soul 进化机制 | ⭐⭐⭐ |
| [007 - 安全沙箱配置](guide/007-security-sandbox.md) | 本机运行的安全配置与沙箱隔离 | ⭐⭐⭐ |
| [008 - 组网与远程沙箱](guide/008-remote-sandbox.md) | 绿联 NAS + macOS + Tailscale 远程部署 | ⭐⭐⭐⭐ |
| [009 - 故障排查](guide/009-troubleshooting.md) | 常见问题、排错流程、注意事项 | ⭐⭐ |
| [010 - 使用场景与用户旅程](guide/010-usage-scenarios.md) | 实际案例：从日常助手到团队协作 | ⭐⭐ |

### guide/openclaw-alternatives/ — 国产替代方案

国内各大厂商基于 OpenClaw 生态推出的 AI Agent 产品对比与选型指南。

| 产品 | 厂商 | 定位 |
|------|------|------|
| [WorkBuddy / QClaw](guide/openclaw-alternatives/tencent-workbuddy-qclaw.md) | 腾讯 | 企微/微信/QQ 深度集成 |
| [CoPaw / QoderWork](guide/openclaw-alternatives/alibaba-copaw-qoderwork.md) | 阿里 | 开源工作台 + 本地部署 |
| [扣子 OpenClaw](guide/openclaw-alternatives/bytedance-coze-openclaw.md) | 字节跳动 | 零代码云端部署 |
| [KimiClaw](guide/openclaw-alternatives/moonshot-kimiclaw.md) | 月之暗面 | 超长上下文云端 Agent |
| [LobsterAI](guide/openclaw-alternatives/netease-lobsterai.md) | 网易有道 | 开源桌面 Agent，教育/办公场景 |
| [MiClaw](guide/openclaw-alternatives/xiaomi-miclaw.md) | 小米 | 手机系统级 Agent，IoT 生态联动 |
| [千帆 OpenClaw](guide/openclaw-alternatives/baidu-qianfan-openclaw.md) | 百度 | 云端一键部署，百度 App 集成 |

总览对比与选型建议见 [openclaw-alternatives/README.md](guide/openclaw-alternatives/README.md)。

---

## testcase/ — 验证测试用例

每章指南对应一个测试用例文件，包含具体操作步骤、测试目标和预期结果，用于验证配置是否正确完成。

```
testcase/
├── 001-macos-installation.md   # 安装验证：版本号检查、doctor 诊断
├── 002-basic-configuration.md  # 配置验证：文件结构、首次启动
├── 003-api-configuration.md    # API 连通性测试
├── 004-messaging-platforms.md  # 平台接入验证
├── 005-tool-integration.md     # MCP 工具调用测试
├── 006-skills-and-evolution.md # 技能安装与记忆持久化测试
├── 007-security-sandbox.md     # 沙箱隔离验证
├── 008-remote-sandbox.md       # 远程连接与 Tailscale 网络测试
├── 009-troubleshooting.md      # 故障场景复现与修复验证
└── 010-usage-scenarios.md      # 端到端使用场景测试
```

---

## scripts/ — 实用脚本

三个自动化脚本，覆盖安装、维护、诊断全流程。

| 脚本 | 用途 | 用法 |
|------|------|------|
| [install.sh](scripts/install.sh) | macOS 一键安装，支持 Homebrew / npm / Docker | `bash scripts/install.sh [homebrew\|npm\|docker]` |
| [backup.sh](scripts/backup.sh) | 备份 `~/.openclaw/` 配置、记忆和代理文件 | `bash scripts/backup.sh [备份目录]` |
| [health-check.sh](scripts/health-check.sh) | 全面检查安装、配置、安全和运行状态 | `bash scripts/health-check.sh` |

**推荐使用流程：**

```bash
# 首次安装
bash scripts/install.sh

# 修改配置前备份
bash scripts/backup.sh

# 日常巡检
bash scripts/health-check.sh
```

详细说明见 [scripts/README.md](scripts/README.md)。

---

## 前置要求

- macOS 12 (Monterey) 或更高版本
- 终端基本操作经验
- 至少一个 LLM API Key（详见 [003 章节](guide/003-api-configuration.md)）
- （可选）Docker Desktop（用于沙箱模式）

## 参考来源

- [OpenClaw 官方文档](https://docs.openclaw.ai/)
- [OpenClaw GitHub 仓库](https://github.com/openclaw/openclaw)
- [ClawHub 技能市场](https://clawhub.dev/)
- [OpenClaw 安全指南（Nebius）](https://nebius.com/blog/posts/openclaw-security)

## 许可证

[MIT](LICENSE)
