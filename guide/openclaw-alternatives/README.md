# 国内 OpenClaw 类产品指南

> 国内大厂基于 OpenClaw 生态推出的各类 AI Agent 产品，涵盖云端托管、本地桌面、IM 集成等形态，帮助你根据使用场景和需求选型。

---

## 什么是 OpenClaw？

[OpenClaw](https://github.com/OpenClaw/OpenClaw)（前身 Clawdbot / Moltbot）是 2026 年初爆火的开源个人 AI 智能体框架，由 Peter Steinberger 创建，GitHub Stars 超过 19.5 万。它允许用户将 AI Agent 部署在本地或私有云，通过 Signal、Telegram、Discord、WhatsApp 等消息平台进行交互，能够主动操作系统、访问网页、处理邮件、整理文件、编写代码——从"建议"到"执行"。

国内各大厂商迅速跟进，推出了兼容 OpenClaw 技能（Skills）的变种产品，有的加了 GUI，有的深度集成自有生态（微信/企微/钉钉/飞书），有的做了云端全托管。

---

## 产品目录

| 厂商 | 产品 | 定位 | 文档 |
|------|------|------|------|
| [腾讯](tencent-workbuddy-qclaw.md) | WorkBuddy / QClaw | B 端办公 + C 端个人 | 企微/微信/QQ 深度集成 |
| [阿里](alibaba-copaw-qoderwork.md) | CoPaw / QoderWork | 开源工作台 + 商业桌面端 | 钉钉/飞书 + 本地部署 |
| [字节跳动](bytedance-coze-openclaw.md) | 扣子 OpenClaw | 零代码云端部署 | 飞书/微信/钉钉接入 |
| [月之暗面](moonshot-kimiclaw.md) | KimiClaw | 云端全托管 | 超长上下文 Agent |
| [网易有道](netease-lobsterai.md) | LobsterAI | 桌面 Agent（已开源） | 教育/办公场景 |
| [小米](xiaomi-miclaw.md) | MiClaw | 手机系统级 Agent | IoT 生态联动 |
| [百度](baidu-qianfan-openclaw.md) | 千帆 OpenClaw | 云端一键部署 | 百度 App 搜索集成 |

---

## 产品总览

| 产品 | 厂商 | 免部署 | 兼容 OpenClaw Skills | IM 集成 | 本地部署 | 开源 | GUI |
|------|------|--------|---------------------|---------|---------|------|-----|
| WorkBuddy | 腾讯 | ✅ | ✅ | 企微/QQ/飞书/钉钉 | ❌ | ❌ | ✅ |
| QClaw | 腾讯 | ✅ | ✅ | 微信/QQ | ✅ | ❌ | ✅ |
| CoPaw | 阿里 | ❌ | ✅ | 钉钉/飞书/QQ/Discord | ✅ | ✅ | ✅ |
| QoderWork | 阿里 | ✅ | 部分 | — | ✅（桌面端） | ❌ | ✅ |
| 扣子 OpenClaw | 字节 | ✅ | ✅ | 飞书/微信/钉钉 | ❌ | ❌ | ✅ |
| KimiClaw | 月之暗面 | ✅ | ✅ | — | ❌ | ❌ | ✅ |
| LobsterAI | 网易有道 | ✅ | ✅（MCP） | — | ✅ | ✅ | ✅ |
| MiClaw | 小米 | ✅ | 部分 | — | ✅（手机端） | ❌ | ✅ |
| 千帆 OpenClaw | 百度 | ✅ | ✅ | 百度 App | ❌ | ❌ | ✅ |

---

## 综合能力对比

| 维度 | WorkBuddy | QClaw | CoPaw | QoderWork | 扣子 OC | KimiClaw | LobsterAI | MiClaw |
|------|-----------|-------|-------|-----------|---------|----------|-----------|--------|
| 上手门槛 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Skills 生态 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| IM 集成 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐ |
| 数据隐私 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 企业级能力 | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| 自定义灵活度 | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| 性价比 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 市场分层

| 类型 | 代表产品 | 特点 |
|------|---------|------|
| **云端托管派** | KimiClaw、扣子 OpenClaw、千帆 OpenClaw | 零门槛，开箱即用，数据在云端 |
| **本地开源派** | CoPaw、LobsterAI | 数据不出本地，可深度定制，需一定技术基础 |
| **IM 原生派** | WorkBuddy、QClaw | 在微信/企微/QQ 中直接对话使用 |
| **桌面 Agent 派** | QoderWork、LobsterAI | 本地桌面应用，操作文件和办公软件 |
| **设备系统派** | MiClaw | 集成到手机操作系统，联动 IoT 设备 |

---

## 选型建议

### 按场景推荐

| 场景 | 推荐产品 | 理由 |
|------|---------|------|
| **企业办公自动化** | WorkBuddy | 企微原生集成、安全审计、内置 20+ Skills |
| **个人微信/QQ 使用** | QClaw | 唯一打通个人微信的 OpenClaw 变体 |
| **零代码快速上手** | 扣子 OpenClaw | 可视化拖拽、免费实例、飞书/微信接入 |
| **隐私优先 / 自托管** | CoPaw | 开源免费、3 条命令部署、数据全本地 |
| **桌面办公文档处理** | QoderWork | Word/Excel/PPT 一键生成、文件批量处理 |
| **长任务链 / 复杂 Agent** | KimiClaw | Kimi K2.5 超长上下文，适合深度任务 |
| **教育/学习场景** | LobsterAI | 教育场景优化、已开源、MCP 协议支持 |
| **智能家居 / IoT 联动** | MiClaw | 手机系统级 Agent，50+ 系统工具和 IoT 设备 |
| **已有百度生态** | 千帆 OpenClaw | 百度 App 搜索直接调用，云端一键部署 |

### 按技术背景推荐

| 用户类型 | 推荐方案 | 说明 |
|---------|---------|------|
| 非技术用户 | WorkBuddy / KimiClaw / 扣子 OC | 安装即用或云端使用，无需配置 |
| 有一定技术基础 | CoPaw / QClaw | 本地部署、自定义 Skill 开发 |
| 开发者 / 极客 | OpenClaw 原版 + 国产模型 API | 最大灵活度，可接入豆包/Kimi/DeepSeek 等低价模型 |
| 企业 IT 团队 | WorkBuddy + CoPaw | B 端安全管控 + 私有化部署 |

---

> **注意**：以上信息截至 2026 年 3 月。OpenClaw 生态变化极快，各产品功能和定价可能随版本更新而改变，请以各厂商官网最新信息为准。
