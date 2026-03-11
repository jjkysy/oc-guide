# 004 - 通讯软件配置

> 详细介绍如何将 OpenClaw 连接到各主流通讯平台：Telegram、WhatsApp、Signal、Discord 等。

## 架构概述

OpenClaw 使用 **Gateway 架构**：一个长期运行的 Gateway 进程通过 WebSocket 接收来自不同平台的消息，路由到同一个会话存储中。

这意味着：**如果你在 WhatsApp 上开始一个对话，稍后可以在 Telegram 上继续** —— 前提是将这些身份绑定到同一个用户。

### 通用配置模式

所有平台的配置都遵循相同的 DM 策略模式：

```json5
{
  "channels": {
    "<platform>": {
      "enabled": true,
      "dmPolicy": "pairing",     // 见下方策略说明
      "allowFrom": [],           // 白名单
      "groupPolicy": "disabled"  // 群组策略
    }
  }
}
```

**DM 策略选项**：

| 策略 | 说明 | 安全性 |
|------|------|--------|
| `pairing` | 首次需配对验证 | ⭐⭐⭐ 推荐 |
| `allowlist` | 仅白名单用户可对话 | ⭐⭐⭐⭐ |
| `open` | 任何人都可以对话 | ⭐ 不推荐 |
| `disabled` | 禁止 DM | ⭐⭐⭐⭐⭐ |

> **安全提示**：一定要设置白名单，尤其在 WhatsApp 和 Telegram 上。一个接受任何人消息的机器人是安全隐患。

---

## Telegram（推荐入门平台）

Telegram 是最容易配置的平台，有正式的 Bot API，工具成熟稳定。OpenClaw 的 Telegram 集成使用 [grammY](https://grammy.dev/) 库。

### 1. 创建 Telegram Bot

1. 在 Telegram 中搜索 **@BotFather**
2. 发送 `/newbot`
3. 按提示设置 Bot 名称和用户名
4. 获得 Bot Token（格式如 `123456789:ABCdefGhIJKlmNoPQRsTUVwxYZ`）

### 2. 配置 OpenClaw

```json5
// ~/.openclaw/openclaw.json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "pairing",
      "ackReaction": "👀",           // 收到消息时的表情回应
      "sendReadReceipts": true,
      "textChunkLimit": 4096,         // Telegram 消息长度限制
      "mediaMaxMb": 50                // 媒体文件大小限制
    }
  }
}
```

```bash
echo 'export TELEGRAM_BOT_TOKEN="your-bot-token"' >> ~/.zshrc
source ~/.zshrc
```

### 3. 测试连接

```bash
openclaw start
```

在 Telegram 中找到你的 Bot，发送一条消息测试。首次对话时 Bot 会要求配对验证。

---

## WhatsApp

WhatsApp 通过 WhatsApp Web 协议连接，使用 QR 码配对。

### 1. 配置

```json5
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "dmPolicy": "pairing",
      "sendReadReceipts": false,      // 建议关闭已读回执
      "mediaMaxMb": 16
    }
  }
}
```

### 2. QR 码配对

```bash
openclaw start
```

启动后终端会显示 QR 码。使用手机 WhatsApp 扫描：

1. 打开 WhatsApp → **设置** → **关联设备**
2. 扫描终端中的 QR 码

### 3. 注意事项

- WhatsApp 使用非官方库连接，**可能因协议更新而中断**
- 建议使用独立的 WhatsApp 号码，不要用主号
- 支持群组、媒体文件和端到端加密消息
- 连接可能需要定期重新配对

> **⚠️ 风险提示**：使用非官方 WhatsApp API 可能违反 WhatsApp 服务条款，存在被封号风险。建议使用不重要的号码。

---

## Signal

Signal 提供端到端加密通讯，是隐私性最高的选择。需要安装 signal-cli。

### 1. 安装 signal-cli

```bash
brew install signal-cli
```

### 2. 注册/关联 Signal

```bash
# 使用已有号码关联（推荐）
signal-cli link -n "OpenClaw Agent"
# 会显示一个链接，用 Signal App 扫描
```

### 3. 配置 OpenClaw

```json5
{
  "channels": {
    "signal": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["+86138xxxx1234"]    // 仅允许特定号码
    }
  }
}
```

### 4. 注意事项

- Signal 支持为**实验性**，可能需要额外配置
- 隐私排名最高：Signal > Matrix > Telegram
- 建议使用 `allowlist` 策略严格限制访问

---

## Discord

Discord 适合社区场景和团队使用。

### 1. 创建 Discord Bot

1. 访问 [Discord Developer Portal](https://discord.com/developers/applications)
2. 点击 **New Application** → 命名
3. 进入 **Bot** 页面 → **Add Bot**
4. 复制 Bot Token
5. 在 **OAuth2 → URL Generator** 中生成邀请链接，选择 `bot` 权限
6. 使用生成的链接邀请 Bot 到你的 Server

### 2. 配置 OpenClaw

```json5
{
  "channels": {
    "discord": {
      "enabled": true,
      "botToken": "${DISCORD_BOT_TOKEN}",
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist"         // 仅在允许的频道中响应
    }
  }
}
```

### 3. 功能支持

- 支持 DM、频道消息
- 支持 Discord 原生功能（嵌入、反应等）
- 适合团队共享代理场景

---

## Slack

适合企业和团队工作场景。

### 1. 创建 Slack App

1. 访问 [api.slack.com/apps](https://api.slack.com/apps)
2. 创建新 App → **From scratch**
3. 配置 Bot Token Scopes：`chat:write`, `channels:read`, `im:read`, `im:write`
4. 安装到 Workspace，获取 Bot Token

### 2. 配置

```json5
{
  "channels": {
    "slack": {
      "enabled": true,
      "botToken": "${SLACK_BOT_TOKEN}",
      "appToken": "${SLACK_APP_TOKEN}",
      "dmPolicy": "pairing"
    }
  }
}
```

---

## 其他支持的平台

OpenClaw 还支持以下平台：

| 平台 | 适用场景 | 成熟度 |
|------|----------|--------|
| iMessage | Apple 生态个人使用 | 稳定 |
| Google Chat | Google Workspace 团队 | 稳定 |
| MS Teams | 微软企业用户 | 稳定 |
| Mattermost | 自托管团队通讯 | 稳定 |
| Matrix | 去中心化通讯 | 稳定 |
| IRC | 传统 IRC 网络 | 稳定 |
| 飞书 (Feishu) | 国内企业用户 | 社区维护 |
| LINE | 日韩用户 | 社区维护 |
| WebChat | 浏览器 UI / 嵌入网页 | 稳定 |

## 多平台用户身份绑定

如果你需要在多个平台间保持会话连贯：

```bash
# 将不同平台的身份绑定到同一用户
openclaw user bind telegram:@your_username whatsapp:+86138xxxx1234
```

## 平台选择建议

| 需求 | 推荐平台 |
|------|----------|
| 个人日常使用 | Telegram / WhatsApp / iMessage |
| 高隐私需求 | Signal |
| 工作/企业 | Slack / MS Teams |
| 社区/团队 | Discord |
| 浏览器访问 | WebChat |
| 国内企业 | 飞书 |

## 下一步

通讯平台配置完成后，进入 [005 - 工具类软件配置](005-tool-integration.md) 接入更多生产力工具。

## 参考来源

- [OpenClaw 官方文档 - Gateway 配置](https://docs.openclaw.ai/gateway/configuration)
- [LumaDock - OpenClaw 多平台设置](https://lumadock.com/tutorials/openclaw-multi-channel-setup)
- [EasyClawd - 最佳通讯平台比较](https://www.easyclawd.com/blog/choose-your-channel)
- [OpenClaw GitHub README](https://github.com/openclaw/openclaw/blob/main/README.md)
