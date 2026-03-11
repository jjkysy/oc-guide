# 002 - 基本配置与运行

> 安装完成后的首次配置、目录结构说明和基本运行指南。

## 首次运行：引导向导

安装后首次运行 OpenClaw 会启动引导向导（Onboarding Wizard）：

```bash
openclaw
```

向导会依次引导你完成：

1. **选择 AI 模型提供商** — Anthropic / OpenAI / OpenRouter / 本地模型
2. **输入 API Key** — 或选择稍后配置
3. **选择通讯平台** — Telegram / WhatsApp / Signal 等
4. **Gateway 模式** — 本地模式 (local) 或远程模式 (remote)

完成后，OpenClaw 会自动生成配置文件并启动 Gateway 服务。

## 目录结构

OpenClaw 的所有配置和数据都存储在 `~/.openclaw/` 目录下：

```
~/.openclaw/
├── openclaw.json          # 主配置文件（JSON5 格式）
├── credentials/           # API 密钥和认证信息（加密存储）
├── agents/                # 代理配置
│   ├── default/
│   │   ├── SOUL.md        # 代理的"灵魂"——人格和行为定义
│   │   ├── MEMORY.md      # 长期记忆
│   │   └── AGENTS.md      # 代理能力说明
├── memory/                # 短期记忆（每日日志）
│   ├── 2026-03-10.md
│   └── 2026-03-11.md
├── sessions/              # 会话数据
├── skills/                # 本地技能覆盖
└── logs/                  # 运行日志
```

## 核心配置文件：openclaw.json

OpenClaw 使用 **JSON5** 格式的配置文件，支持注释和尾逗号。

> **重要**：配置文件采用严格验证，未知的键会导致 Gateway 拒绝启动。

### 最小可用配置

```json5
{
  // Gateway 基本设置
  "gateway": {
    "mode": "local",       // "local" 或 "remote"
    "port": 18789          // 默认端口
  },

  // 代理配置
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6"  // 默认使用的模型
    }
  },

  // 通讯平台（至少配置一个）
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN"
    }
  }
}
```

### 完整配置结构概览

```json5
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "loopback",           // "loopback" | "tailnet" | "0.0.0.0"
    "auth": { /* 认证设置 */ },
    "controlUi": { /* 控制面板设置 */ }
  },

  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6",
      "contextWindow": 200000,     // 最小 16000
      "maxConcurrent": 3,
      "sandbox": { /* 沙箱配置 */ }
    },
    "list": [
      // 特定代理配置（覆盖 defaults）
    ]
  },

  "channels": {
    "telegram": { /* ... */ },
    "whatsapp": { /* ... */ },
    "signal":   { /* ... */ },
    "discord":  { /* ... */ }
  },

  "models": {
    "providers": [
      // 自定义模型提供商
    ]
  },

  "tools": {
    "allow": [],                    // 允许的工具列表
    "deny": [],                     // 禁止的工具列表
    "elevated": { /* 提权设置 */ }
  },

  "memory": {
    "search": { /* 记忆搜索设置 */ }
  },

  "cron": {
    "enabled": false,
    "maxConcurrentRuns": 2
  },

  "hooks": {
    "enabled": false
  }
}
```

## 常用 CLI 命令

### 配置管理

```bash
# 查看当前配置
openclaw config get

# 设置单个配置项
openclaw config set gateway.port 18790

# 删除配置项
openclaw config unset channels.telegram.botToken

# 验证配置
openclaw doctor
```

### Gateway 管理

```bash
# 启动 Gateway
openclaw start

# 停止 Gateway
openclaw stop

# 查看状态
openclaw status

# 查看日志
openclaw logs
openclaw logs --tail 50
```

### 代理管理

```bash
# 列出所有代理
openclaw agent list

# 创建新代理
openclaw agent create my-agent

# 查看代理详情
openclaw agent info my-agent
```

## 环境变量

敏感信息不应直接写在配置文件中，使用环境变量引用：

```json5
{
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}"
    }
  }
}
```

在 `~/.zshrc` 中设置：

```bash
export TELEGRAM_BOT_TOKEN="your-token-here"
export ANTHROPIC_API_KEY="sk-ant-xxx"
```

## 热重载

Gateway 会**监听配置文件变更并自动重载**，大部分设置修改后无需手动重启。

以下设置是例外，修改后需要重启：

- `gateway.reload`
- `gateway.remote`

> **提示**：优先使用 `openclaw config set/unset/get` 命令修改配置，而非手动编辑文件。

## 配置拆分（$include）

大型配置可以拆分为多个文件：

```json5
{
  "channels": { "$include": "./channels.json5" },
  "agents":   { "$include": "./agents.json5" },
  "models":   { "$include": ["./models-base.json5", "./models-custom.json5"] }
}
```

- 单文件替换所在对象
- 数组形式的多文件按顺序深度合并
- 支持最多 10 层嵌套引用

## 下一步

配置完成后，进入 [003 - API 获取与配置](003-api-configuration.md) 设置你的 LLM API Key。

## 参考来源

- [OpenClaw 官方配置文档](https://docs.openclaw.ai/gateway/configuration)
- [OpenClaw 入门指南](https://docs.openclaw.ai/start/getting-started)
- [LumaDock - OpenClaw CLI 与配置参考](https://lumadock.com/tutorials/openclaw-cli-config-reference)
- [DeepWiki - 配置文件结构](https://deepwiki.com/openclaw/openclaw/4.1-configuration-file-structure)
