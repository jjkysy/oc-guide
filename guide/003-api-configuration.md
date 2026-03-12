# 003 - API 获取与配置

> 详细介绍三类 LLM API 的获取、充值和配置方法：Anthropic Claude（国外）、Moonshot Kimi（国内）、OpenRouter（综合渠道）。

## 概述

OpenClaw 是模型无关的，支持多种 LLM 提供商。你至少需要配置一个 API Key 才能使用。

**提供商优先级**（当多个 API Key 同时存在时）：

1. Anthropic API Key → Claude 模型作为主模型
2. OpenAI API Key → GPT 模型作为主模型
3. OpenRouter API Key → 作为兜底使用

> **重要提示**：自 2026 年初起，Anthropic 已禁止在 OpenClaw 等第三方工具中使用 Claude Pro/Max 的 OAuth 令牌。请使用 **API Key** 方式接入。

---

## 一、Anthropic Claude（国外主流）

Claude 是 OpenClaw 社区中使用最广泛的模型，尤其擅长工具调用和代理任务。

### 1.1 注册与获取 API Key

1. 访问 [console.anthropic.com](https://console.anthropic.com/)
2. 使用邮箱注册账户（支持 Google 账号登录）
3. 进入 **API Keys** 页面
4. 点击 **Create Key**，记下生成的 Key（以 `sk-ant-` 开头）

> **注意**：API Key 只在创建时显示一次，请立即保存。

### 1.2 充值

1. 在控制台进入 **Billing** 页面
2. 添加信用卡（支持 Visa / Mastercard / American Express）
3. 充值建议：
   - 入门测试：$5-10
   - 日常使用：$20-50/月
   - 重度使用：$100+/月

> **Tips**：新注册账户通常会获得 $5 免费额度。

### 1.3 可用模型

| 模型 | 特点 | 适用场景 |
|------|------|----------|
| Claude Opus 4.6 (`claude-opus-4-6`) | 最强能力，最慢速度 | 复杂推理任务 |
| Claude Sonnet 4.6 (`claude-sonnet-4-6`) | 能力与速度平衡 | 日常代理（推荐） |
| Claude Haiku 4.5 (`claude-haiku-4-5`) | 最快速度，最便宜 | 简单对话、快速回复 |

### 1.4 配置到 OpenClaw

```bash
# 方式一：CLI 命令
openclaw config set agents.defaults.model "claude-sonnet-4-6"

# 方式二：环境变量
echo 'export ANTHROPIC_API_KEY="sk-ant-your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

在 `openclaw.json` 中的配置：

```json5
{
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6",
      // 必须使用 anthropic-messages 格式，否则工具调用会 400 错误
      "api": "anthropic-messages"
    }
  }
}
```

> **关键**：Claude 必须使用 `anthropic-messages` 格式（设置 `api: "anthropic-messages"`），使用 `openai-completions` 格式会导致多轮工具调用时出现 400 错误。

---

## 二、Moonshot Kimi（国内主流）

Kimi 是国内头部 AI 公司月之暗面推出的大语言模型，中文能力出色，且对 OpenClaw 有良好兼容性。

### 2.1 注册与获取 API Key

1. 访问 [platform.moonshot.cn](https://platform.moonshot.cn/)
2. 使用手机号注册
3. 进入 **API 密钥管理** 页面
4. 创建新的 API Key

### 2.2 充值

1. 在平台进入 **费用中心**
2. 支持支付宝 / 微信支付充值
3. 充值建议：
   - 入门测试：¥10-30
   - 日常使用：¥50-100/月
   - 新注册通常有免费额度

### 2.3 可用模型

| 模型 | 特点 | 适用场景 |
|------|------|----------|
| Kimi K2.5 | 综合能力强，性价比高 | 日常代理（推荐） |
| Kimi K2.5 Coding | 代码优化版本 | 编程任务 |

### 2.4 配置到 OpenClaw

Kimi 使用 OpenAI 兼容接口：

```json5
{
  "models": {
    "providers": [
      {
        "name": "moonshot",
        "api": "openai-completions",
        "baseUrl": "https://api.moonshot.cn/v1",
        "apiKey": "${MOONSHOT_API_KEY}",
        "models": ["kimi-k2.5"]
      }
    ]
  },
  "agents": {
    "defaults": {
      "model": "kimi-k2.5"
    }
  }
}
```

环境变量设置：

```bash
echo 'export MOONSHOT_API_KEY="your-moonshot-key"' >> ~/.zshrc
source ~/.zshrc
```

> **注意**：Kimi 也提供 Anthropic 兼容端点 `https://api.moonshot.ai/anthropic`，可用于需要 `anthropic-messages` 格式的场景。

---

## 三、OpenRouter（综合渠道）

OpenRouter 是一个 LLM API 聚合平台，通过一个 API Key 即可访问数百个模型。适合需要灵活切换模型的用户。

### 3.1 注册与获取 API Key

1. 访问 [openrouter.ai](https://openrouter.ai/)
2. 使用 Google / GitHub 账号注册
3. 进入 **Keys** 页面
4. 创建新的 API Key（以 `sk-or-` 开头）

### 3.2 充值

1. 进入 **Credits** 页面
2. 支持信用卡 / 加密货币充值
3. 充值建议：
   - 入门测试：$5
   - 日常使用：$10-30/月

> **Tips**：OpenRouter 上部分模型（如某些开源模型）是免费的，可以零成本试用。

### 3.3 可用模型（示例）

| 模型 ID | 提供商 | 特点 |
|---------|--------|------|
| `openrouter/anthropic/claude-sonnet-4.5` | Anthropic | 通过 OpenRouter 使用 Claude |
| `openrouter/google/gemini-pro-1.5` | Google | Gemini 系列 |
| `openrouter/moonshotai/kimi-k2.5` | Moonshot | 通过 OpenRouter 使用 Kimi |
| `openrouter/openrouter/auto` | 自动路由 | 自动选择性价比最高的模型 |

### 3.4 配置到 OpenClaw

OpenClaw 内置 OpenRouter 支持，无需配置 `models.providers`：

```bash
# 设置 API Key
echo 'export OPENROUTER_API_KEY="sk-or-your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

在 `openclaw.json` 中使用 `openrouter/<provider>/<model>` 格式引用模型：

```json5
{
  "agents": {
    "defaults": {
      "model": "openrouter/anthropic/claude-sonnet-4.5"
    }
  }
}
```

---

## 模型回退（Fallback）

OpenClaw 支持模型回退机制，当主模型不可用时自动切换：

```json5
{
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6",
      "fallback": [
        "kimi-k2.5",
        "openrouter/openrouter/auto"
      ]
    }
  }
}
```

这在 OpenRouter 的提供商级别故障转移基础上，提供了额外的可靠性层。

## 成本优化建议

1. **日常对话** → 使用 Haiku 4.5 或 Kimi K2.5（便宜快速）
2. **复杂任务** → 切换到 Sonnet 4.5 或 Opus 4.5
3. **预算有限** → OpenRouter 的 `auto` 路由自动选择性价比最优模型
4. **混合策略** → 主模型用 Kimi（¥15/月左右），回退用 OpenRouter

## 验证配置

```bash
# 检查所有配置是否正确
openclaw doctor

# 测试模型连接
openclaw start
# 然后通过配置好的通讯平台发送一条测试消息
```

## 下一步

API 配置完成后，进入 [004 - 通讯软件配置](004-messaging-platforms.md) 连接你的即时通讯平台。

## 参考来源

- [OpenClaw 官方文档 - Anthropic 提供商](https://docs.openclaw.ai/providers/anthropic)
- [OpenRouter - OpenClaw 集成文档](https://openrouter.ai/docs/guides/guides/openclaw-integration)
- [Moonshot 开放平台](https://platform.moonshot.cn/)
- [Medium - OpenClaw Without Claude: $15/Month Setup With Kimi K2.5](https://medium.com/@rentierdigital/anthropic-just-killed-my-200-month-openclaw-setup-so-i-rebuilt-it-for-15-9cab6814c556)
- [AI Free API - Clawdbot API Key 与 OpenRouter 集成指南](https://www.aifreeapi.com/en/posts/clawdbot-api-key-openrouter-integration)
