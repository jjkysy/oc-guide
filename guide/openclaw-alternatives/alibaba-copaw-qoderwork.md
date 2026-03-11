# 阿里 — CoPaw / QoderWork

> [返回目录](README.md)

## 简介

阿里在 OpenClaw 生态中推出两款产品：**CoPaw** 是通义实验室推出的开源个人智能体工作台，主打"本地+云端"双部署；**QoderWork** 是 Qoder 团队推出的商业化桌面端 AI 智能体，侧重办公文档处理。两者互补，CoPaw 面向技术用户，QoderWork 面向办公场景。

## 产品形态

| 产品 | 定位 | 说明 |
|------|------|------|
| **CoPaw** | 开源个人智能体 | 基于 AgentScope 构建，3 条命令部署，支持钉钉/飞书/QQ/Discord/iMessage 多频道对话，长期记忆系统 |
| **QoderWork** | 商业桌面 Agent | Mac + Windows 双平台，本地文件操作、Word/Excel/PPT/PDF 生成，Ask/Agent/Quest 三大工作模式 |

## 特点与优劣

### CoPaw

**优势：**
- 完全开源免费，部署简单（3 条命令）
- 数据全部留在本地，隐私安全
- 支持 DashScope、Ollama、llama.cpp、MLX 等多种推理后端
- 自定义 Skill 开发 + Skills Hub 社区共享
- 长期记忆系统，主动记录用户偏好
- 内置定时任务、PDF/文档处理、新闻摘要等功能
- 成本约为商业方案的 1/10

**劣势：**
- 需要一定技术基础进行部署和维护
- 无官方 GUI 客户端（社区有第三方）
- 企业级支持和 SLA 不如商业产品

### QoderWork

**优势：**
- 桌面端应用，安装即用
- 专业文档生成能力强（Word/Excel/PPT/PDF）
- 支持模型分级选择器，轻量任务可节省成本
- Mac + Windows 双平台支持

**劣势：**
- 订阅制收费，高级功能价格较高
- IM 集成能力弱
- OpenClaw Skills 兼容性有限

## 定价参考

### CoPaw

开源免费，费用仅取决于所接入的大模型 API 消耗。

### QoderWork

| 套餐 | 价格 | Credits | 适用人群 |
|------|------|---------|---------|
| Free | $0/月 | 300 | 轻度体验 |
| Pro | $10/月 | 2,000 | 个人开发者 |
| Pro+ | $30/月 | 6,000 | 进阶用户 |
| Ultra | $100/月 | 20,000 | 高频专业开发者 |
| Teams | $30/席位/月 | 2,000/席位 | 小型团队 |
| Enterprise | 待定 | — | 大型组织 |

> 价格可能随时调整，请以官网为准。

## 相关链接

- CoPaw 部署教程：https://developer.aliyun.com/article/1713682
- QoderWork：https://qoderwork.com
- 阿里云 AI 开发者社区：https://developer.aliyun.com
