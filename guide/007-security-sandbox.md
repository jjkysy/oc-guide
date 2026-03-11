# 007 - 安全沙箱配置

> 本机运行 OpenClaw 的安全配置、Docker 沙箱隔离、权限控制和安全最佳实践。

## 安全模型概述

OpenClaw **继承其所在机器的所有信任和凭据**。这意味着：

- 代理能访问你的文件系统
- 代理能执行 Shell 命令
- 代理能使用你机器上的 SSH 密钥、API Token 等

> 应将 OpenClaw **视为"带有持久凭据的不可信代码执行"**。

## 沙箱模式

沙箱控制 OpenClaw 被允许在系统上做什么。

### 配置沙箱

```json5
// openclaw.json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",    // 沙箱模式
        "docker": {
          "image": "openclaw/sandbox:latest",
          "setupCommand": "apt-get update && apt-get install -y curl",
          "workspaceMount": "readwrite",  // "readwrite" | "readonly" | "none"
          "networkAccess": true
        }
      }
    }
  }
}
```

### 沙箱模式选项

| 模式 | 说明 | 安全性 | 灵活性 |
|------|------|--------|--------|
| `none` | 不使用沙箱，所有操作在宿主机执行 | ⭐ | ⭐⭐⭐⭐⭐ |
| `non-main` | 群聊和非主线程在容器中运行，主会话在宿主机 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| `all` | 所有工具调用都在 Docker 容器中执行 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

### 工作区挂载选项

```json5
{
  "sandbox": {
    "docker": {
      "workspaceMount": "readonly"    // 容器只能读取工作区，不能写入
    }
  }
}
```

| 选项 | 说明 |
|------|------|
| `readwrite` | 容器可读写工作区 |
| `readonly` | 容器只能读取工作区 |
| `none` | 不挂载工作区到容器 |

## 工具权限控制

### Allow/Deny 列表

```json5
{
  "tools": {
    "allow": [
      "memory_search",
      "memory_get",
      "search_emails",
      "read_email",
      "draft_email",
      "list_events",
      "create_event"
    ],
    "deny": [
      "send_email",        // 禁止自动发送邮件
      "delete_file",       // 禁止删除文件
      "make_payment",      // 禁止支付
      "execute_shell"      // 禁止执行 Shell 命令
    ]
  }
}
```

### 提权模式（Elevated）

```json5
{
  "tools": {
    "elevated": {
      "enabled": true,
      "allowedSenders": ["telegram:@your_username"],
      "commands": [
        "ls", "cat", "grep", "find"     // 仅允许这些命令
      ]
    }
  }
}
```

> 提权模式允许特定发送者在 Gateway 宿主机上运行命令，务必严格限制。

## 执行审批

OpenClaw 可以在执行敏感操作前要求你的明确确认：

```json5
{
  "agents": {
    "defaults": {
      "execApproval": true    // 开启执行审批
    }
  }
}
```

开启后，代理在执行 Shell 命令、发送消息等操作前会先发送确认请求。

**建议**：在安装新技能或测试新功能时保持开启，待信任行为后再关闭。

## 技能安全

### requires.bins 检查

`SKILL.md` 中的 `requires.bins` 在技能加载时在宿主机上检查。如果代理在沙箱中运行，二进制文件也必须在容器内存在。

```yaml
# SKILL.md frontmatter
requires:
  bins: [node, python3, curl]
```

通过 `setupCommand` 安装：

```json5
{
  "sandbox": {
    "docker": {
      "setupCommand": "apt-get update && apt-get install -y nodejs python3 curl"
    }
  }
}
```

> `setupCommand` 在容器创建后运行一次。安装包还需要网络出口、可写根文件系统和容器内 root 用户。

### 安全审计命令

```bash
# 全面安全审计
openclaw security audit

# 自动修复可修复的问题
openclaw security audit --fix

# 查看当前会话的有效沙箱策略
openclaw sandbox explain

# 查看特定会话的沙箱策略
openclaw sandbox explain --session <session-id>

# 运行后建议在以下时机重复运行：
# - 每次配置变更后
# - 每次安装新技能后
# - 定期巡检（建议每周一次）
```

## macOS 特有的安全考虑

### 1. 文件系统权限

macOS 的沙箱机制（App Sandbox）会限制某些目录的访问。确保 OpenClaw 有权访问需要的目录：

```bash
# 检查 OpenClaw 可访问的目录
ls -la ~/openclaw/workspace/
ls -la ~/.openclaw/
```

### 2. 网络权限

首次运行时 macOS 可能会弹出防火墙提示，请允许 OpenClaw Gateway 接受传入连接。

### 3. 签名构建

在 macOS 上，签名构建是确保权限在重新构建后仍然生效的前提。使用 Homebrew 安装的版本已经处理了签名。

### 4. Keychain 访问

OpenClaw 可能尝试访问 Keychain 中的凭据。建议创建独立的 Keychain 用于 OpenClaw：

```bash
security create-keychain -p "" ~/Library/Keychains/openclaw.keychain-db
```

## 安全配置模板

### 保守模式（推荐新手使用）

```json5
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",
        "docker": {
          "workspaceMount": "readonly",
          "networkAccess": false
        }
      },
      "execApproval": true
    }
  },
  "tools": {
    "deny": ["send_email", "delete_file", "execute_shell", "make_payment"]
  },
  "channels": {
    "telegram": {
      "dmPolicy": "allowlist",
      "allowFrom": ["@your_username"]
    }
  }
}
```

### 日常使用模式

```json5
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",
        "docker": {
          "workspaceMount": "readwrite",
          "networkAccess": true
        }
      },
      "execApproval": false
    }
  },
  "tools": {
    "deny": ["send_email", "make_payment"]
  }
}
```

### 最大权限模式（仅限受信环境）

```json5
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "none"
      },
      "execApproval": false
    }
  },
  "tools": {
    "elevated": {
      "enabled": true,
      "allowedSenders": ["telegram:@your_username"]
    }
  }
}
```

> **⚠️ 警告**：最大权限模式仅应在受信环境中使用，且必须严格限制 `allowedSenders`。

## 安全最佳实践总结

| 实践 | 说明 |
|------|------|
| 不要暴露 Gateway 到公网 | 绑定到 loopback，使用 SSH 隧道或 Tailscale |
| 设置白名单 | 尤其在 WhatsApp 和 Telegram 上 |
| 审查每个 SKILL.md | 安装前阅读所有指令和脚本 |
| 首次运行用沙箱 | 新技能先在沙箱中测试 |
| 保持 exec 审批开启 | 直到完全信任行为 |
| 定期运行安全审计 | `openclaw security audit --fix` |
| 敏感数据放宿主机 | 凭据、SSH 密钥不放容器里 |
| 重要指令写 SOUL.md | 不要只在对话中说 |
| 使用独立账号 | 通讯平台用不重要的号码 |
| 定期备份 | 备份 `~/.openclaw/` 目录 |

## 下一步

进入 [008 - 组网与远程沙箱](008-remote-sandbox.md) 了解如何通过 NAS 和 Tailscale 实现远程部署。

## 参考来源

- [Nebius - OpenClaw 安全架构和加固指南](https://nebius.com/blog/posts/openclaw-security)
- [HackMD - Docker 安全优先指南](https://hackmd.io/@Ramshreyas/Hy9IQUNOZg)
- [AI Maker - OpenClaw 安全加固三层实施指南](https://aimaker.substack.com/p/openclaw-security-hardening-guide)
- [VirusTotal - OpenClaw 技能被武器化](https://blog.virustotal.com/2026/02/from-automation-to-infection-how.html)
- [LumaDock - 技能安全指南](https://lumadock.com/tutorials/openclaw-skills-guide)
