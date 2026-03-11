# 005 - 工具类软件配置

> 详细介绍浏览器、日历、邮件、支付等 MCP 工具集成，以及如何判断和接入新工具。

## MCP 协议简介

OpenClaw 的工具集成基于 **MCP（Model Context Protocol）**。MCP 定义了一个通用协议，让任何 AI 应用都能发现和调用工具。

- ClawHub 上的每个技能本质上就是一个 MCP Server
- 启用一个技能时，OpenClaw 连接到对应的 MCP Server，使其工具对代理可用
- ClawHub 目前托管了 **3,200+ MCP 技能**

### MCP 配置方式

有两种主要的 MCP 工具配置方式：

#### 方式一：通过 Composio（托管 MCP）

```json5
// openclaw.json
{
  "plugins": {
    "entries": {
      "composio": {
        "enabled": true,
        "config": {
          "consumerKey": "ck_your_key_here"
        }
      }
    }
  }
}
```

Composio 提供统一的 MCP Server（`https://connect.composio.dev/mcp`），注册后通过 OAuth 连接各种服务。

#### 方式二：直接配置 MCP Server

```bash
# 设置自定义 MCP Server
openclaw config set mcpServers.myserver.command "node /path/to/server.js"
openclaw config set mcpServers.myserver.env.API_KEY "your-key"
```

---

## 浏览器自动化

让 OpenClaw 操控浏览器：获取网页内容、点击元素、填写表单、截图等。

### 配置 Browser Tool MCP

```bash
# 安装浏览器技能
openclaw skill install browser-tool
```

或通过 Composio 连接：

```json5
{
  "mcpServers": {
    "browser": {
      "command": "npx",
      "args": ["@anthropic/mcp-browser"],
      "env": {}
    }
  }
}
```

### 功能列表

- 获取网页内容并转 Markdown
- 点击、输入、滚动等交互操作
- 页面截图
- 表单自动填充
- JavaScript 执行

### 安全建议

- 浏览器工具权限较高，建议在 Docker 沙箱中运行
- 不要让代理访问银行、证券等敏感网站
- 设置 URL 白名单限制可访问的域名

---

## 日历管理

日历集成通常是**投资回报最高的集成** —— 可以在凌晨自动处理预约。

### Google Calendar

```bash
# 安装 Google Calendar 技能
openclaw skill install openclaw-google-calendar
```

技能实际上是一个 MCP Server，暴露以下工具：

| 工具 | 功能 |
|------|------|
| `create_event` | 创建日历事件 |
| `list_events` | 列出即将到来的事件 |
| `update_event` | 修改事件 |
| `delete_event` | 删除事件 |
| `find_free_slots` | 查找空闲时间段 |

### Apple Calendar（通过 Composio）

```json5
{
  "plugins": {
    "entries": {
      "composio": {
        "enabled": true,
        "config": {
          "consumerKey": "ck_your_key",
          "tools": ["apple_calendar"]
        }
      }
    }
  }
}
```

### 使用场景

- "帮我约明天下午3点和张三开会"
- "查看我下周的日程安排"
- "取消今天所有标记为'可选'的会议"

---

## 邮件管理

### Gmail

```bash
openclaw skill install gmail-mcp
```

功能包括：

| 工具 | 功能 |
|------|------|
| `search_emails` | 搜索邮件 |
| `read_email` | 读取邮件内容 |
| `draft_email` | 起草邮件 |
| `send_email` | 发送邮件 |
| `manage_labels` | 管理标签 |
| `manage_contacts` | 管理联系人 |

### Outlook

```bash
openclaw skill install outlook-mcp
```

支持邮件、日历和联系人的统一管理。

### 安全提示

- **发送邮件权限需要格外谨慎** —— 考虑仅开启草稿权限，手动确认后再发送
- 可以配置 `tools.deny` 禁止自动发送：

```json5
{
  "tools": {
    "deny": ["send_email"],     // 禁止自动发送
    "allow": ["draft_email", "search_emails", "read_email"]
  }
}
```

---

## 支付与金融

> **⚠️ 高风险区域**：支付和金融工具涉及资金安全，需极度谨慎。

### 建议策略

1. **仅监控，不操作** —— 让代理查看账单和消费记录，但不执行支付
2. **多重确认** —— 任何涉及金额的操作都需要你的明确确认
3. **金额限制** —— 如果允许自动支付，设置严格的金额上限

### 示例：查看消费记录

```json5
{
  "tools": {
    "allow": ["check_balance", "list_transactions"],
    "deny": ["make_payment", "transfer_funds"]
  }
}
```

---

## 文件与存储

### 本地文件系统

OpenClaw 默认可以访问 `~/openclaw/workspace/` 目录下的文件。

```json5
{
  "agents": {
    "defaults": {
      "workspace": "~/openclaw/workspace"
    }
  }
}
```

### 云存储（Google Drive / Dropbox）

```bash
openclaw skill install google-drive-mcp
openclaw skill install dropbox-mcp
```

---

## 如何判断和接入新工具

当你想要接入一个新的生产力工具（如即梦、PS、Notion 等）时，按以下流程评估：

### 评估清单

```
1. 是否有官方 MCP Server？
   → 查看 ClawHub 搜索结果
   → 查看工具官方文档中是否提到 MCP 支持

2. 是否有 API？
   → 有 REST API → 可以自建 MCP Server
   → 有 OpenAPI/Swagger → 可以自动生成 MCP Server
   → 无 API → 只能通过浏览器自动化（效率较低）

3. 是否有 Composio 集成？
   → 访问 composio.dev/toolkits 搜索
   → 一键 OAuth 连接，最简单

4. 是否有 Zapier/Make 集成？
   → 可通过 Zapier MCP 间接接入
   → 适合简单的触发-动作场景

5. 安全性评估
   → 工具需要的权限级别？
   → 是否涉及敏感数据？
   → 是否需要沙箱隔离？
```

### 自建 MCP Server

如果你需要的工具没有现成的 MCP 集成，可以自建：

```bash
# 使用 OpenClaw 技能创建器
openclaw skill create my-custom-tool
```

这会生成一个技能模板：

```
my-custom-tool/
├── SKILL.md          # 技能描述和指令
├── server.js         # MCP Server 实现
└── package.json
```

### 接入示例：即梦 AI（Jimeng）

```javascript
// server.js - 自建 MCP Server 示例
import { MCPServer } from '@openclaw/mcp-sdk';

const server = new MCPServer({
  name: 'jimeng-ai',
  tools: {
    generate_image: {
      description: '使用即梦 AI 生成图片',
      parameters: {
        prompt: { type: 'string', description: '图片描述' },
        style: { type: 'string', enum: ['realistic', 'anime', 'oil'] }
      },
      handler: async ({ prompt, style }) => {
        // 调用即梦 API
        const result = await fetch('https://api.jimeng.ai/v1/generate', {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${process.env.JIMENG_API_KEY}` },
          body: JSON.stringify({ prompt, style })
        });
        return result.json();
      }
    }
  }
});
```

### 推荐集成优先级

| 优先级 | 工具类型 | 原因 |
|--------|----------|------|
| 1 | 日历 | 自动预约带来即时 ROI |
| 2 | 邮件 | 邮件分类和草稿节省大量时间 |
| 3 | 文件系统 | 基础操作能力 |
| 4 | 浏览器 | 扩展信息获取能力 |
| 5 | 其他 | 按个人需求优先级排列 |

## 下一步

工具配置完成后，进入 [006 - 技能与进化配置](006-skills-and-evolution.md) 了解技能管理和代理进化机制。

## 参考来源

- [Composio - OpenClaw Browser Tool MCP](https://composio.dev/toolkits/browser_tool/framework/openclaw)
- [Composio - Google Calendar MCP](https://composio.dev/toolkits/googlecalendar/framework/openclaw)
- [Composio - Gmail MCP](https://composio.dev/toolkits/gmail/framework/openclaw)
- [OpenClaw Launch - MCP 技能指南](https://openclawlaunch.com/guides/openclaw-mcp)
- [ClawTank - OpenClaw MCP Server 集成指南](https://clawtank.dev/blog/openclaw-mcp-server-integration)
- [My Legal Academy - OpenClaw MCP 集成](https://mylegalacademy.com/kb/openclaw-mcp-integrations)
