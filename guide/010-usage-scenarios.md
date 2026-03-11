# 010 - 使用场景与用户旅程

> 从日常助手到团队协作，展示 OpenClaw 的实际使用场景和完整用户旅程。

## 场景一：个人日常助手

> **用户画像**：独立开发者，使用 Telegram 与 OpenClaw 交互

### 典型一天

```
07:30  [自动] OpenClaw 发送今日日程摘要
       "早上好！今天你有 3 个会议，2 个待办任务。
        09:00 团队周会（Zoom）
        14:00 客户演示（Google Meet）
        16:00 1:1（Slack Huddle）
        待办：完成 API 文档、审查 PR #42"

08:00  [用户] "帮我查看收件箱有什么重要邮件"
       [代理] 扫描 Gmail，按重要性排序返回摘要

09:30  [用户] "帮我把昨天的会议笔记整理成文档"
       [代理] 读取 memory/2026-03-10.md，生成结构化文档

12:00  [用户] "附近有什么好吃的？帮我看看评分高的"
       [代理] 通过浏览器搜索附近餐厅，返回筛选结果

14:30  [用户] "帮我起草一封邮件回复客户，告诉他们新功能下周上线"
       [代理] 草拟邮件（不自动发送），等待确认

18:00  [自动] OpenClaw 汇总今日工作，写入 memory/2026-03-11.md
```

### 配置要点

```json5
{
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["@your_username"]
    }
  },
  "cron": {
    "enabled": true,
    "jobs": [
      {
        "name": "morning-briefing",
        "schedule": "0 7 30 * * *",
        "prompt": "查看今日日历和待办，发送简要摘要"
      },
      {
        "name": "evening-summary",
        "schedule": "0 18 0 * * *",
        "prompt": "汇总今日工作，保存到记忆文件"
      }
    ]
  }
}
```

---

## 场景二：开发者工作流

> **用户画像**：全栈开发者，使用 Discord 在团队服务器中与 OpenClaw 交互

### 代码审查协助

```
[用户]  "审查 PR #42 的代码变更"
[代理]  → 通过 GitHub MCP 获取 PR diff
        → 分析代码质量、潜在问题
        → 返回结构化审查意见

[用户]  "帮我把审查意见发到 PR 评论中"
[代理]  → 通过 GitHub API 提交评论
```

### 自动化部署监控

```
[Webhook]  GitHub Actions 部署完成通知
[代理]     → 检查部署状态
           → 运行基础健康检查
           → 如果失败：通知用户并附上日志摘要
           → 如果成功：更新部署记录
```

### 配置要点

```json5
{
  "channels": {
    "discord": {
      "enabled": true,
      "dmPolicy": "pairing"
    }
  },
  "hooks": {
    "enabled": true,
    "mappings": {
      "/deploy": {
        "agent": "devops",
        "prompt": "检查最新部署状态"
      }
    }
  }
}
```

---

## 场景三：信息研究与知识管理

> **用户画像**：产品经理，需要持续追踪行业动态

### 用户旅程

```
Step 1: 设置定期研究任务
[用户]  "每天早上帮我检查以下信息源的更新：
        - Hacker News 前 10
        - Product Hunt 今日新品
        - 竞品 A、B、C 的博客更新"

Step 2: 代理自动执行
[代理]  → 使用浏览器工具访问各信息源
        → 提取关键信息
        → 生成每日摘要
        → 保存到工作区文件
        → 通过 Telegram 发送摘要

Step 3: 深度研究
[用户]  "详细分析竞品 A 最新发布的功能"
[代理]  → 浏览竞品官网和文档
        → 对比自家产品功能
        → 生成分析报告

Step 4: 知识积累
[代理]  → 将研究成果写入 MEMORY.md
        → 下次提问时自动引用历史研究
```

---

## 场景四：多代理协作

> **用户画像**：小团队负责人，需要多个专业化代理

### 代理分工

| 代理名 | 职责 | 通道 |
|--------|------|------|
| `planner` | 任务规划和分解 | Slack #planning |
| `coder` | 代码编写和审查 | Discord #dev |
| `writer` | 文档和内容创作 | Telegram DM |
| `scout` | 信息收集和研究 | 自动 (cron) |

### 配置

```json5
{
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6"
    },
    "list": [
      {
        "name": "planner",
        "soul": "./agents/planner/SOUL.md",
        "model": "claude-opus-4-6"    // 复杂推理用 Opus
      },
      {
        "name": "coder",
        "soul": "./agents/coder/SOUL.md",
        "sandbox": { "mode": "all" }
      },
      {
        "name": "writer",
        "soul": "./agents/writer/SOUL.md",
        "model": "kimi-k2.5"          // 中文写作用 Kimi
      },
      {
        "name": "scout",
        "soul": "./agents/scout/SOUL.md",
        "model": "claude-haiku-4-5"    // 简单任务用 Haiku
      }
    ]
  },
  "bindings": [
    { "channel": "slack", "room": "#planning", "agent": "planner" },
    { "channel": "discord", "room": "#dev", "agent": "coder" },
    { "channel": "telegram", "user": "@your_name", "agent": "writer" }
  ]
}
```

> **参考**：[openclaw-agents](https://github.com/shenhao-stu/openclaw-agents) 提供了 9 个预配置专业代理的一键部署方案。

---

## 场景五：NAS 部署的家庭助手

> **用户画像**：技术爱好者，在绿联 NAS 上部署 OpenClaw 作为家庭 AI 中心

### 家庭场景

```
[家人通过 WhatsApp]
  "今天晚上吃什么？冰箱里有鸡蛋、西红柿和面条"
  → 代理推荐食谱并给出步骤

[用户通过 Telegram]
  "帮我看看明天的天气，如果下雨提醒我带伞"
  → 代理设置天气检查任务

[定时任务]
  每周日晚 → 汇总本周家庭支出
  每月 1 号 → 提醒缴纳水电费
```

### 安全策略

```json5
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": [
        "+86138xxxx1234",      // 本人
        "+86139xxxx5678"       // 家人
      ],
      "groupPolicy": "disabled"
    }
  },
  "tools": {
    "deny": ["execute_shell", "delete_file", "make_payment"]
  }
}
```

---

## 使用技巧

### 1. SOUL.md 编写建议

```markdown
# 好的 SOUL.md 模板

## 身份
你是我的个人 AI 助手，名字叫小助。

## 沟通风格
- 中文为主，技术术语保留英文
- 简洁直接，不要客套
- 不确定时先问，不要猜测

## 行为规则
- 所有涉及发送（邮件、消息、支付）的操作必须先确认
- 代码修改前先备份
- 每天结束时自动总结并保存记忆

## 知识边界
- 不提供医疗、法律、财务建议
- 不确定的信息明确标注
```

### 2. 高效提示词

```
# 明确具体 ✅
"帮我查看 Gmail 中来自 alice@example.com 的最近 5 封邮件，
 并按时间排序列出主题"

# 模糊笼统 ❌
"看看我的邮件"

# 带约束条件 ✅
"搜索 Hacker News 上关于 AI Agent 的文章，
 只要今天的，最多返回 5 篇，附上链接"

# 无约束 ❌
"找些 AI 相关的文章"
```

### 3. 记忆管理

```bash
# 定期清理过期的每日日志（保留 30 天）
find ~/.openclaw/memory -name "*.md" -mtime +30 -delete

# 手动编辑长期记忆
open ~/.openclaw/agents/default/MEMORY.md

# 检查 SOUL.md 是否被意外修改
git -C ~/.openclaw diff agents/default/SOUL.md
```

### 4. 成本控制

| 策略 | 方法 |
|------|------|
| 模型分级 | 简单任务用 Haiku，复杂任务用 Sonnet |
| 限制自主行为 | 关闭 cron 中不必要的定时任务 |
| 上下文管理 | 定期清理记忆，减少每次调用的 token 数 |
| 监控用量 | 在 API 提供商控制台设置预算告警 |

## 参考来源

- [OpenClaw 官方文档](https://docs.openclaw.ai/)
- [Medium - 用 OpenClaw 替代 6+ 应用](https://medium.com/@srechakra/sda-f079871369ae)
- [shenhao-stu/openclaw-agents - 多代理部署](https://github.com/shenhao-stu/openclaw-agents)
- [OpenClaw Blog - 平台集成指南](https://openclawblog.space/articles/openclaw-platform-integrations)
