# 011 - 高风险操作审批工作流

> 为支付、组织管理等高风险操作配置强制人工审批，防止 AI 代理在无监督状态下执行不可逆操作。

## 为什么需要人工审批？

OpenClaw 能够执行真实的外部操作：发起支付、管理组织成员、发送邮件、修改文件系统。这些操作一旦执行，往往**不可撤销或撤销代价很高**。

典型高风险场景：

| 类别 | 示例操作 | 风险 |
|------|----------|------|
| 支付 | Stripe 扣款、微信/支付宝转账、购买云资源 | 资金损失 |
| 组织管理 | 邀请/移除成员、修改权限、删除项目 | 数据丢失、权限泄露 |
| 外部通讯 | 代发邮件、代发 Slack/Discord 消息 | 声誉损失 |
| 文件系统 | 删除文件、覆盖重要数据 | 数据丢失 |
| API 调用 | 触发 Webhook、修改 DNS、操作云服务 | 服务中断 |

---

## 一、审批工作流机制

OpenClaw 提供两种方式拦截高风险操作：

1. **工具级别审批（Tool Approval）**：对特定工具的所有调用强制人工确认
2. **操作规则审批（Approval Rules）**：基于参数内容动态判断是否需要审批

---

## 二、工具级别审批配置

### 2.1 全局工具审批

在 `openclaw.json` 中，对指定工具开启强制审批：

```json5
{
  "agents": {
    "defaults": {
      "tools": {
        // 支付工具 — 每次调用都需人工确认
        "stripe_charge": {
          "approval": "always"
        },
        "stripe_refund": {
          "approval": "always"
        },
        "wechat_pay": {
          "approval": "always"
        },

        // 组织管理工具 — 每次调用都需人工确认
        "github_add_member": {
          "approval": "always"
        },
        "github_remove_member": {
          "approval": "always"
        },
        "slack_send_message": {
          "approval": "always"
        },

        // 文件删除 — 每次调用都需人工确认
        "fs_delete": {
          "approval": "always"
        },
        "fs_overwrite": {
          "approval": "always"
        },

        // 邮件发送 — 每次调用都需人工确认
        "email_send": {
          "approval": "always"
        }
      }
    }
  }
}
```

### 2.2 审批值说明

| 值 | 含义 |
|----|------|
| `"always"` | 每次调用都强制人工确认 |
| `"never"` | 从不询问（慎用） |
| `"first-run"` | 每个参数组合首次运行时确认 |
| `"on-change"` | 参数变化时确认 |

---

## 三、操作规则审批（Approval Rules）

比工具级别更精细，可以**基于参数内容**动态决定是否需要审批。

### 3.1 基于金额的支付审批

```json5
{
  "agents": {
    "defaults": {
      "approvalRules": [
        // 超过 100 元的支付操作必须审批
        {
          "name": "large-payment",
          "match": {
            "tool": "stripe_charge",
            "params": {
              "amount": { "greaterThan": 10000 }   // 单位：分，10000 = 100 元
            }
          },
          "action": "require-approval",
          "message": "支付金额超过 100 元，需要确认。"
        },
        // 任意金额支付都审批（更保守的策略）
        {
          "name": "any-payment",
          "match": {
            "tool": { "pattern": "*_pay|*_charge|*_transfer" }
          },
          "action": "require-approval",
          "message": "检测到支付操作，请确认。"
        }
      ]
    }
  }
}
```

### 3.2 组织操作审批规则

```json5
{
  "agents": {
    "defaults": {
      "approvalRules": [
        // 移除组织成员必须审批
        {
          "name": "remove-member",
          "match": {
            "tool": { "pattern": "*_remove_member|*_kick|*_ban" }
          },
          "action": "require-approval",
          "message": "将要移除组织成员：{params.username}，请确认。"
        },

        // 修改他人权限必须审批
        {
          "name": "change-permissions",
          "match": {
            "tool": { "pattern": "*_set_role|*_grant_*|*_revoke_*" }
          },
          "action": "require-approval",
          "message": "将要修改 {params.username} 的权限，请确认。"
        },

        // 删除项目/仓库必须审批
        {
          "name": "delete-repo",
          "match": {
            "tool": { "pattern": "*_delete_repo|*_delete_project" }
          },
          "action": "require-approval",
          "message": "⚠️ 将要删除 {params.name}，此操作不可逆，请确认。"
        }
      ]
    }
  }
}
```

### 3.3 文件操作审批规则

```json5
{
  "agents": {
    "defaults": {
      "approvalRules": [
        // 删除文件需审批
        {
          "name": "file-delete",
          "match": {
            "tool": "fs_delete"
          },
          "action": "require-approval",
          "message": "将要删除文件：{params.path}，请确认。"
        },

        // 写入敏感目录需审批
        {
          "name": "sensitive-path-write",
          "match": {
            "tool": { "pattern": "fs_write|fs_overwrite" },
            "params": {
              "path": { "pattern": "^/(etc|usr|System|private).*" }
            }
          },
          "action": "require-approval",
          "message": "将要写入系统目录 {params.path}，请确认。"
        }
      ]
    }
  }
}
```

---

## 四、审批通道配置

审批请求会通过你配置的通讯平台发送给你，你回复确认或拒绝。

### 4.1 Telegram 审批

```json5
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": ["@your_username"],
      "approval": {
        "enabled": true,
        "timeout": 300,           // 等待 5 分钟，超时自动取消
        "onTimeout": "cancel"     // "cancel" 或 "proceed"（建议 cancel）
      }
    }
  }
}
```

审批交互示例：

```
Bot: ⚠️ 审批请求
     操作：stripe_charge
     金额：¥ 299.00
     收款方：Acme Corp
     原因：购买年度订阅

     请回复：
     ✅ 确认  ❌ 拒绝
     （5 分钟内未回复将自动取消）

You: ✅ 确认

Bot: ✓ 操作已执行，支付成功。
```

### 4.2 超时策略

```json5
{
  "approvalDefaults": {
    "timeout": 300,           // 等待确认的秒数
    "onTimeout": "cancel",    // 超时后取消（推荐），不要用 "proceed"
    "notifyOnTimeout": true   // 超时后通知你
  }
}
```

> **重要**：`onTimeout` 强烈建议设为 `"cancel"` 而非 `"proceed"`。如果你忘记回复，默认拒绝比默认执行要安全得多。

---

## 五、为特定代理配置更严格的规则

不同代理可以有不同的审批策略：

```json5
{
  "agents": {
    // 默认代理：标准审批规则
    "defaults": {
      "tools": {
        "stripe_charge": { "approval": "always" }
      }
    },

    // 财务助手：所有外部操作都需审批
    "finance-bot": {
      "extends": "defaults",
      "tools": {
        // 继承 defaults，并添加更多限制
        "stripe_charge":  { "approval": "always" },
        "stripe_refund":  { "approval": "always" },
        "invoice_send":   { "approval": "always" },
        "expense_create": { "approval": "always" }
      },
      "approvalRules": [
        {
          "name": "any-money-movement",
          "match": { "tool": { "pattern": "*charge*|*pay*|*refund*|*transfer*" } },
          "action": "require-approval"
        }
      ]
    },

    // 日常助手：只对大额支付审批
    "daily-assistant": {
      "extends": "defaults",
      "approvalRules": [
        {
          "name": "large-payment-only",
          "match": {
            "tool": { "pattern": "*_charge|*_pay" },
            "params": { "amount": { "greaterThan": 50000 } }  // 500 元以上
          },
          "action": "require-approval"
        }
      ]
    }
  }
}
```

---

## 六、审计日志

所有需要审批的操作都会记录在审计日志中，无论批准与否：

```json5
{
  "audit": {
    "enabled": true,
    "logFile": "~/.openclaw/audit.log",
    "includeApprovals": true,    // 记录审批决定
    "includeRejections": true,   // 记录拒绝操作
    "includeParams": true        // 记录操作参数（含敏感信息，注意保护日志文件）
  }
}
```

查看审计日志：

```bash
# 查看最近的高风险操作
openclaw audit --tail 50

# 只看被拒绝的操作
openclaw audit --filter rejected

# 只看支付相关
openclaw audit --filter "tool:*charge*|*pay*"
```

---

## 七、完整配置示例

适合个人 + 家庭服务器（Mac Studio）场景：

```json5
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "loopback",
    "auth": { "mode": "tailscale", "allowTailscale": true }
  },

  "tailscale": {
    "mode": "serve",
    "hostname": "mac-studio"
  },

  "audit": {
    "enabled": true,
    "logFile": "~/.openclaw/audit.log",
    "includeApprovals": true,
    "includeRejections": true
  },

  "approvalDefaults": {
    "timeout": 300,
    "onTimeout": "cancel",
    "notifyOnTimeout": true
  },

  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6",
      "sandbox": {
        "mode": "all",
        "docker": { "networkAccess": false }
      },

      // 工具级别：高风险工具一律审批
      "tools": {
        "stripe_charge":       { "approval": "always" },
        "stripe_refund":       { "approval": "always" },
        "wechat_pay":          { "approval": "always" },
        "email_send":          { "approval": "always" },
        "fs_delete":           { "approval": "always" },
        "github_add_member":   { "approval": "always" },
        "github_remove_member":{ "approval": "always" }
      },

      // 规则级别：基于内容的动态审批
      "approvalRules": [
        {
          "name": "any-payment",
          "match": { "tool": { "pattern": "*_pay|*_charge|*_transfer" } },
          "action": "require-approval",
          "message": "检测到支付操作：{tool}，请确认。"
        },
        {
          "name": "org-destructive",
          "match": { "tool": { "pattern": "*_remove_*|*_delete_*|*_revoke_*" } },
          "action": "require-approval",
          "message": "检测到组织管理操作：{tool}，请确认。"
        }
      ]
    }
  },

  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": ["@your_username"],
      "approval": {
        "enabled": true,
        "timeout": 300,
        "onTimeout": "cancel"
      }
    }
  }
}
```

---

## 快速检查清单

```
□ 支付工具设置 approval: "always"
□ 组织管理工具设置 approval: "always"
□ 文件删除工具设置 approval: "always"
□ onTimeout 设置为 "cancel"（不是 "proceed"）
□ 审批通道设置了 allowlist（防止他人冒充审批）
□ 审计日志已开启
□ 审计日志文件权限 600
□ 定期检查 openclaw audit 日志
```

---

## 下一步

- [007 - 安全沙箱配置](007-security-sandbox.md)：沙箱隔离与工具权限控制
- [009 - 故障排查](009-troubleshooting.md)：审批流程不工作时的排查方法

## 参考来源

- [OpenClaw 官方文档 - Approval Workflows](https://docs.openclaw.ai/agents/approval-workflows)
- [OpenClaw 官方文档 - Tool Permissions](https://docs.openclaw.ai/agents/tool-permissions)
- [AI Maker - OpenClaw 安全加固三层指南](https://aimaker.substack.com/p/openclaw-security-hardening-guide)
- [Nebius - OpenClaw 安全架构](https://nebius.com/blog/posts/openclaw-security)
