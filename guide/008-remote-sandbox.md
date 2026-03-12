# 008 - 组网与远程沙箱配置

> 以 Mac Studio（中心节点）+ 绿联 NAS（资料库）+ Tailscale 为例，介绍多层隔离的家庭/小团队服务器部署方案。

## 使用场景与角色定义

本方案面向以下典型场景：

```
┌─────────────────────────────────────────────────────────────────┐
│  角色            访问方式              可执行操作               │
├─────────────────────────────────────────────────────────────────┤
│  管理员          可信设备 + Tailscale   修改配置、轮换密钥、     │
│  (你自己)        SSH 到 Mac Studio     查看日志、管理 NAS 备份  │
├─────────────────────────────────────────────────────────────────┤
│  普通用户        Telegram / WhatsApp   通过聊天软件向 OpenClaw  │
│  (家人/同事)     等聊天软件            发送指令，执行日常任务    │
├─────────────────────────────────────────────────────────────────┤
│  OpenClaw 代理   Docker 沙箱内运行     只能读写工作区目录，      │
│  (AI)            受限文件系统和网络    无法触及配置/密钥/备份    │
├─────────────────────────────────────────────────────────────────┤
│  公网攻击者      无任何入口            零公网端口，无法触达      │
└─────────────────────────────────────────────────────────────────┘
```

**关键设计目标**：

1. **沙箱隔离** — OpenClaw 只能操作工作区目录，无法触及配置文件、SSH 密钥、NAS 备份
2. **管理面分离** — 配置和密钥仅管理员通过可信设备维护，外网完全接触不到
3. **入侵容忍** — 即使 OpenClaw 被提示注入或渗透，损失限定在工作区内，备份安全
4. **密钥可控** — 敏感信息加密存储、定期轮换，泄露后可快速止损

---

## 架构概览

```
                  Tailscale 私有网络（WireGuard 端到端加密）
                  ┌───────────────────────────────────────────────────┐
                  │                                                   │
                  │         管理面（仅管理员可信设备）                  │
┌──────────┐      │    ┌──────────────────────────────┐               │
│ MacBook  │◄─────┼───►│        Mac Studio (宿主机)    │               │
│ (管理员)  │ SSH  │    │                              │               │
└──────────┘      │    │  ~/.openclaw/  ← 配置/密钥   │  SMB (tailnet)│
                  │    │  ~/.ssh/       ← SSH 密钥    │◄─────────────►┤
                  │    │                              │               │
                  │    │  ┌──────────────────────┐    │  ┌──────────┐ │
                  │    │  │  Docker 沙箱          │    │  │ 绿联 NAS │ │
                  │    │  │  ┌────────────────┐  │    │  │          │ │
                  │    │  │  │ OpenClaw 代理   │  │    │  │ /workspace│ │
                  │    │  │  │ (受限运行)      │  │    │  │ /backup  │ │
                  │    │  │  └────────────────┘  │    │  │ (仅管理员)│ │
                  │    │  │  挂载: ~/workspace   │    │  └──────────┘ │
                  │    │  │  (只读配置, 读写工作区)│    │               │
                  │    │  │  网络: 默认断网       │    │               │
                  │    │  └──────────────────────┘    │               │
                  │    │                              │               │
                  │    │  Tailscale Serve (HTTPS)     │               │
                  │    │  (tailnet 内可信设备可访问)    │               │
                  │    └──────────────────────────────┘               │
                  │                                                   │
                  │         用户面（聊天软件）                          │
┌──────────┐      │                                                   │
│ 家人手机  │──────┼──► Telegram Bot ──► Gateway ──► Docker 沙箱       │
│ (普通用户) │      │    (公网 Bot API)   (loopback)  (受限执行)        │
└──────────┘      │                                                   │
                  └───────────────────────────────────────────────────┘

公网攻击者 ────── ✗ ──── 无法直接访问 Mac Studio 或 NAS
```

**数据流隔离**：

| 路径 | 方向 | 经过 | 加密 |
|------|------|------|------|
| 管理员 → Mac Studio | 双向 | Tailscale SSH | WireGuard + SSH |
| Mac Studio → NAS | 双向 | Tailscale + SMB | WireGuard + SMB 签名 |
| 用户 → OpenClaw | 单向请求 | Telegram API → Gateway | TLS (Telegram) |
| OpenClaw → 工作区 | 受限 | Docker volume mount | 本地 |

---

## 一、Mac Studio 基础配置（24/7 服务器）

Mac Studio 作为始终运行的中心节点，需要先做系统级配置。

### 1.1 电源管理（防止休眠）

```bash
# 禁用所有休眠（sleep=0 表示永不休眠）
sudo pmset -a sleep 0

# 禁用磁盘休眠
sudo pmset -a disksleep 0

# 掉电后自动重启
sudo pmset -a autorestart 1

# 允许网络唤醒（Tailscale 需要）
sudo pmset -a womp 1

# 验证设置
pmset -g
```

> **提示**：显示器可以休眠（节能），不影响服务运行。如需关闭显示器休眠：`sudo pmset -a displaysleep 0`。

### 1.2 安装 Tailscale

macOS 上推荐通过 Mac App Store 或独立包安装（含 GUI 状态栏图标和系统级 VPN 配置）：

```bash
# 方式一：Homebrew Cask（安装独立 GUI 版本）
brew install --cask tailscale

# 方式二：直接下载独立包（推荐）
# 从 https://pkgs.tailscale.com/stable/ 下载 Tailscale-latest-macos.pkg

# 方式三：Mac App Store
# 搜索 "Tailscale" 安装
```

安装后从菜单栏登录，或使用 CLI：

```bash
# 首次启动并认证（会打开浏览器）
tailscale up

# 查看连接状态
tailscale status
```

> **注意**：macOS 上 `tailscale up` 不需要 `sudo`，因为 Tailscale 通过系统扩展运行。

### 1.3 安装 OpenClaw

```bash
brew tap openclaw/tap && brew install openclaw

# 验证
openclaw --version
openclaw doctor
```

---

## 二、Tailscale 组网

Tailscale 基于 WireGuard 协议，提供端到端加密的私有网络。**无需开放任何路由器端口**。

### 2.1 注册 Tailscale

1. 访问 [tailscale.com](https://tailscale.com/) 注册账号
2. 免费版支持最多 100 台设备，足够家庭/小团队使用

### 2.2 在绿联 NAS 上安装

绿联 NAS（UGOS）通过 Docker 安装 Tailscale：

```bash
# SSH 连接到 NAS（局域网 IP）
ssh root@192.168.1.100

# 确保 tun 内核模块已加载
modprobe tun

# 拉取并运行 Tailscale 容器
docker run -d \
  --name tailscale \
  --hostname ugreen-nas \
  --restart always \
  --cap-add NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -v tailscale-state:/var/lib/tailscale \
  -e TS_STATE_DIR=/var/lib/tailscale \
  --network host \
  tailscale/tailscale:latest

# 认证（按提示在浏览器完成）
docker exec tailscale tailscale up
```

> **注意**：
> - 使用 `--device` 而非 `-v` 挂载 `/dev/net/tun`，这是设备文件不是普通目录
> - 使用 Docker named volume `tailscale-state` 持久化状态，避免容器重建后需重新认证
> - 如绿联应用商店支持 Tailscale，优先用应用商店版本，免去 Docker 配置
> - UGOS 的存储根路径因型号而异（常见 `/volume1/`、`/mnt/media_rw/` 或 `/data/`），请在 NAS 管理界面确认实际路径

### 2.3 在可信设备上安装

- **iPhone / iPad**：App Store 搜索 "Tailscale"
- **MacBook**：Mac App Store 或 `brew install --cask tailscale`
- 登录同一账号即可加入 tailnet

### 2.4 配置 ACL（访问控制列表）

在 [Tailscale 控制台](https://login.tailscale.com/admin/acls) 配置访问规则。

> **关键**：Tailscale ACL 是 **deny-by-default** — 一旦定义了任何 ACL 规则，所有未明确允许的流量都会被拒绝。下面的示例需要覆盖你所有设备间的合理通信需求。

```json5
// Tailscale ACL 配置
{
  "tagOwners": {
    "tag:admin":           ["autogroup:owner"],
    "tag:openclaw-server": ["autogroup:owner"],
    "tag:nas":             ["autogroup:owner"],
    "tag:user-device":     ["autogroup:owner"]
  },
  "acls": [
    // 管理员可以 SSH 管理 Mac Studio（管理面）
    {
      "action": "accept",
      "src": ["tag:admin"],
      "dst": ["tag:openclaw-server:22"]
    },
    // 管理员可信设备访问 OpenClaw 控制面板
    {
      "action": "accept",
      "src": ["tag:admin"],
      "dst": ["tag:openclaw-server:443"]
    },
    // Mac Studio 可以 SMB 访问 NAS（文件共享）
    {
      "action": "accept",
      "src": ["tag:openclaw-server"],
      "dst": ["tag:nas:445"]
    },
    // Mac Studio 可以 SSH 访问 NAS（管理用）
    {
      "action": "accept",
      "src": ["tag:openclaw-server"],
      "dst": ["tag:nas:22"]
    },
    // 管理员也可直接 SSH 到 NAS（备用管理通道）
    {
      "action": "accept",
      "src": ["tag:admin"],
      "dst": ["tag:nas:22"]
    },
    // 用户设备之间允许基本通信（按需调整）
    {
      "action": "accept",
      "src": ["tag:user-device"],
      "dst": ["tag:user-device:*"]
    }
  ]
}
```

**标签分配**：在 Tailscale 控制台 → Machines 页面，为每台设备添加对应标签：

| 设备 | 标签 |
|------|------|
| Mac Studio | `tag:openclaw-server` |
| 绿联 NAS | `tag:nas` |
| 管理员 MacBook | `tag:admin` |
| 家人手机等 | `tag:user-device` |

> **注意**：普通用户（家人）的设备**不需要加入 Tailscale**。他们通过 Telegram/WhatsApp 等公共聊天平台与 OpenClaw 交互，消息经 Bot API 到达 Mac Studio 上的 Gateway。只有管理员才需要 Tailscale 直连。

### 2.5 验证组网

```bash
# 在 Mac Studio 上查看所有设备
tailscale status

# 预期输出示例：
# 100.x.x.1  mac-studio   you@email.com  macOS  -
# 100.x.x.2  ugreen-nas   you@email.com  linux  -
# 100.x.x.3  macbook      you@email.com  macOS  -

# 测试 Mac Studio → NAS 连通性
ping ugreen-nas
```

---

## 三、NAS 配置：资料库与备份

NAS 作为资料库，**不运行 OpenClaw**。它提供两个隔离区域：

| 目录 | 用途 | 谁可访问 |
|------|------|----------|
| `openclaw-workspace/` | OpenClaw 工作区（通过 SMB 挂载） | Mac Studio（OpenClaw 沙箱可读写） |
| `openclaw-backup/` | 配置和数据备份 | 仅管理员（OpenClaw 完全不可见） |

### 3.1 在 NAS 上创建专用账户和目录

在绿联 NAS 管理界面（UGOS）中：

1. **用户管理** → 新建用户 `openclaw-agent`
2. 设置强密码，并仅允许 SSH 密钥登录
3. **权限** → 仅授予 `openclaw-workspace` 共享文件夹的读写权限

```bash
# SSH 到 NAS 执行
# 注意：路径需根据你的 NAS 实际存储根路径调整
# 绿联 UGOS 常见为 /volume1/ 或通过管理界面确认

# 工作区 — OpenClaw 可通过 SMB 挂载访问
mkdir -p /volume1/openclaw-workspace/{projects,archives,uploads}
chown -R openclaw-agent:users /volume1/openclaw-workspace
chmod 750 /volume1/openclaw-workspace

# 备份区 — 仅管理员 SSH 可访问，OpenClaw 完全不可见
mkdir -p /volume1/openclaw-backup/{config,snapshots}
chown -R root:root /volume1/openclaw-backup
chmod 700 /volume1/openclaw-backup
```

### 3.2 在 NAS 上启用 SMB 共享

在绿联 UGOS 管理界面中：

1. **文件服务** → 启用 **SMB/CIFS** 服务
2. 创建共享文件夹 `openclaw-workspace`，授权 `openclaw-agent` 读写
3. **不要** 共享 `openclaw-backup` 目录

### 3.3 Mac Studio 通过 SSH 密钥访问 NAS（管理用）

```bash
# 在 Mac Studio 上生成专用 SSH 密钥
ssh-keygen -t ed25519 -C "openclaw@mac-studio" -f ~/.ssh/id_nas

# 将公钥上传到 NAS
ssh-copy-id -i ~/.ssh/id_nas.pub openclaw-agent@ugreen-nas

# 测试连接
ssh -i ~/.ssh/id_nas openclaw-agent@ugreen-nas "echo 连接成功"
```

配置 `~/.ssh/config` 简化连接：

```
Host ugreen-nas
    HostName ugreen-nas
    User openclaw-agent
    IdentityFile ~/.ssh/id_nas
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 3.4 通过 SMB 挂载 NAS 工作区（推荐）

macOS 原生支持 SMB，**不需要安装任何额外软件**（避免了 SSHFS 依赖 macFUSE 内核扩展的问题）。

```bash
# 创建挂载点
mkdir -p ~/mounts/nas-workspace

# 挂载 NAS SMB 共享（通过 Tailscale 网络）
mount_smbfs //openclaw-agent@ugreen-nas/openclaw-workspace ~/mounts/nas-workspace
```

#### 开机自动挂载

创建 `~/Library/LaunchAgents/com.openclaw.nas-mount.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.openclaw.nas-mount</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>
      # 等待 Tailscale 网络就绪
      for i in $(seq 1 30); do
        tailscale status &amp;&amp; break
        sleep 2
      done
      # 挂载 SMB（密码从 Keychain 读取）
      mount_smbfs //openclaw-agent@ugreen-nas/openclaw-workspace /Users/YOUR_USER/mounts/nas-workspace
    </string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardErrorPath</key>
  <string>/tmp/nas-mount.err</string>
</dict>
</plist>
```

```bash
# 将 SMB 密码存入 Keychain（避免明文）
security add-internet-password -a openclaw-agent -s ugreen-nas \
  -w "YOUR_SMB_PASSWORD" -T /sbin/mount_smbfs

# 加载 LaunchAgent
launchctl load ~/Library/LaunchAgents/com.openclaw.nas-mount.plist
```

> **替换提醒**：将 `YOUR_USER` 替换为你的 macOS 用户名。

#### 备选方案：SSHFS（不推荐）

如确需 SSHFS（例如 NAS 不支持 SMB），需注意：

```bash
# macFUSE 在 Apple Silicon Mac 上需要降低系统安全级别：
# 1. 关机 → 长按电源键进入恢复模式
# 2. 菜单栏 → 实用工具 → 启动安全性实用工具
# 3. 选择"降低安全性" → 允许已验证开发者的内核扩展

# 安装 macFUSE（需重启）
brew install --cask macfuse

# SSHFS 已从 homebrew-core 移除，需用第三方 tap
brew install gromgit/fuse/sshfs-mac

# 挂载（注意 Apple Silicon 上的路径是 /opt/homebrew/bin/sshfs）
sshfs ugreen-nas:/volume1/openclaw-workspace ~/mounts/nas-workspace \
  -o reconnect,ServerAliveInterval=15,IdentityFile=~/.ssh/id_nas
```

> **不推荐 SSHFS 的原因**：需要降低 macOS 系统安全级别来加载内核扩展，每次 macOS 大版本更新后可能需要重新授权，且性能不如 SMB。

---

## 四、OpenClaw 中心节点配置

### 4.1 Gateway 与沙箱配置

创建或编辑 `~/.openclaw/openclaw.json`：

```json5
{
  // ── Gateway 服务器配置 ──
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "loopback",           // 仅绑定 127.0.0.1
    "auth": {
      "mode": "tailscale",        // Tailscale 身份认证
      "allowTailscale": true
    }
  },

  // ── 代理默认设置 ──
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6",
      "api": "anthropic-messages",
      "sandbox": {
        "mode": "all",            // 所有操作都在 Docker 沙箱中
        "docker": {
          "workspaceMount": "readwrite",
          "networkAccess": false   // 沙箱默认断网
        }
      }
    }
  },

  // ── 通讯平台 ──
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": [
        "@admin_username",         // 管理员
        "@family_member"           // 家人（普通用户）
      ]
    }
  }
}
```

**沙箱隔离的关键**：`sandbox.mode: "all"` 意味着 OpenClaw 的所有工具调用都在 Docker 容器内执行。容器只挂载了工作区目录，**无法访问**：

| 资源 | 沙箱内可见？ | 说明 |
|------|------------|------|
| `~/mounts/nas-workspace/` | 是（读写） | 工作区，通过 Docker volume 挂载 |
| `~/.openclaw/openclaw.json` | 否 | 配置文件在宿主机，容器外 |
| `~/.openclaw/.env` | 否 | 密钥文件在宿主机，以环境变量注入 |
| `~/.ssh/` | 否 | SSH 密钥在宿主机 |
| `~/mounts/nas-backup/` | 不存在 | 备份区从未挂载到 Mac Studio |
| 宿主机文件系统 | 否 | Docker 沙箱隔离 |

### 4.2 配置 Tailscale Serve

Tailscale Serve 将 Mac Studio 上的本地服务安全地暴露给 tailnet 内的设备，自动提供 HTTPS 证书。

```bash
# 在 Mac Studio 上执行（需先启用 HTTPS 证书）
# Tailscale Serve 将 localhost:18789 代理为 tailnet HTTPS
tailscale serve 18789

# 验证：从管理员 MacBook 访问
# https://mac-studio.your-tailnet.ts.net
```

> **Serve vs Funnel**：`tailscale serve` 仅 tailnet 内可访问（安全）；`tailscale funnel` 暴露到公网（危险，仅 Webhook 场景使用）。

### 4.3 启用 Tailscale SSH（管理员远程管理）

```bash
# 在 Mac Studio 上开启 Tailscale SSH
tailscale set --ssh

# 从管理员 MacBook 连接（使用 Tailscale 身份认证，无需密码）
ssh your-username@mac-studio
```

> **注意**：`tailscale set --ssh` 是持久设置。执行后 Tailscale 会拦截发往 Mac Studio 的 SSH 流量，使用 Tailscale 身份认证代替传统 SSH 密钥。

### 4.4 设置为 launchd 系统服务（开机自启）

```bash
# OpenClaw 引导向导通常会自动安装，也可手动管理：
launchctl list | grep openclaw

# 启动/停止
launchctl start com.openclaw.gateway
launchctl stop  com.openclaw.gateway

# 设置登录后自动启动
launchctl enable gui/$(id -u)/com.openclaw.gateway
```

---

## 五、密钥与敏感信息管理

### 5.1 环境变量隔离

敏感信息通过 `.env` 文件注入，**不写入配置文件**，不进入 Docker 沙箱：

```bash
# ~/.openclaw/.env（仅 owner 可读）
ANTHROPIC_API_KEY=sk-ant-api03-your-key
TELEGRAM_BOT_TOKEN=123456789:ABCxxx
GATEWAY_PASSWORD=your-strong-password
```

```bash
chmod 600 ~/.openclaw/.env
```

OpenClaw Gateway 在**宿主机**读取 `.env`，将必要的值作为环境变量传递给 Docker 沙箱。沙箱内的代理可以调用 API（通过 Gateway 代理），但**无法读取 `.env` 文件本身**。

### 5.2 API 密钥定期轮换

创建密钥轮换脚本 `~/.openclaw/scripts/rotate-keys.sh`：

```bash
#!/bin/bash
# 密钥轮换脚本 — 建议每 7-30 天执行一次
# 用法：手动执行，或通过 cron 定期触发

set -euo pipefail

ENV_FILE="$HOME/.openclaw/.env"
BACKUP_DIR="$HOME/.openclaw/key-history"
LOG_FILE="$HOME/.openclaw/logs/key-rotation.log"

mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

echo "[$(date -Iseconds)] 开始密钥轮换..." >> "$LOG_FILE"

# 1. 备份当前 .env（加密存储）
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
cp "$ENV_FILE" "$BACKUP_DIR/.env.$TIMESTAMP"
chmod 600 "$BACKUP_DIR/.env.$TIMESTAMP"

# 2. 提示管理员更新密钥
echo "=== 密钥轮换 ==="
echo "请在以下平台生成新 API Key 并替换："
echo "  1. Anthropic Console → API Keys → Create Key"
echo "  2. Telegram @BotFather → /revoke（可选，轮换 Bot Token）"
echo ""
echo "当前 .env 位置：$ENV_FILE"
echo "编辑完成后按 Enter 继续..."
read -r

# 3. 验证新密钥格式
source "$ENV_FILE"
if [[ ! "$ANTHROPIC_API_KEY" =~ ^sk-ant- ]]; then
  echo "错误：ANTHROPIC_API_KEY 格式不正确" >&2
  exit 1
fi

# 4. 重启 Gateway 使新密钥生效
launchctl stop com.openclaw.gateway
sleep 2
launchctl start com.openclaw.gateway

echo "[$(date -Iseconds)] 密钥轮换完成" >> "$LOG_FILE"
echo "轮换完成。请在原平台撤销旧 API Key。"
```

```bash
chmod 700 ~/.openclaw/scripts/rotate-keys.sh
```

### 5.3 轮换策略建议

| 密钥 | 建议轮换周期 | 泄露后影响 | 止损方式 |
|------|-------------|-----------|---------|
| `ANTHROPIC_API_KEY` | 每 30 天 | 被盗用产生费用 | Console 立即撤销 + 设 Spending Limit |
| `TELEGRAM_BOT_TOKEN` | 每 90 天或泄露时 | Bot 被冒用 | @BotFather `/revoke` |
| `GATEWAY_PASSWORD` | 每 30 天 | 控制面板被访问 | 改密码 + 重启 |
| NAS SMB 密码 | 每 90 天 | 工作区被访问 | NAS 界面改密码 |

> **自动化提醒**：可设置 cron 每月 1 号提醒轮换：
> ```bash
> echo "0 9 1 * * echo '提醒：该轮换 API 密钥了' | mail -s '密钥轮换提醒' you@email.com" | crontab -
> ```

---

## 六、备份与容灾

### 6.1 自动备份策略

创建定时备份脚本 `~/.openclaw/scripts/backup.sh`：

```bash
#!/bin/bash
# OpenClaw 配置和记忆备份 — 备份到 NAS 的隔离备份区
set -euo pipefail

BACKUP_DIR="/volume1/openclaw-backup/snapshots"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TARGET="$BACKUP_DIR/openclaw-$TIMESTAMP.tar.gz"

# 通过 SSH 在 NAS 上创建备份（不使用 SMB，用管理员 SSH 通道）
ssh ugreen-nas "mkdir -p $BACKUP_DIR"

# 打包配置（排除日志和缓存）
tar -czf /tmp/openclaw-backup.tar.gz \
  -C "$HOME" \
  .openclaw/openclaw.json \
  .openclaw/agents/ \
  .openclaw/skills/ \
  .openclaw/credentials/ \
  --exclude='*.log' \
  --exclude='sessions/'

# 传输到 NAS 备份区
scp /tmp/openclaw-backup.tar.gz "ugreen-nas:$TARGET"
rm /tmp/openclaw-backup.tar.gz

# 清理 30 天前的备份
ssh ugreen-nas "find $BACKUP_DIR -name '*.tar.gz' -mtime +30 -delete"

echo "[$(date -Iseconds)] 备份完成: $TARGET"
```

```bash
chmod 700 ~/.openclaw/scripts/backup.sh

# 每天凌晨 3 点自动备份
(crontab -l 2>/dev/null; echo "0 3 * * * $HOME/.openclaw/scripts/backup.sh >> $HOME/.openclaw/logs/backup.log 2>&1") | crontab -
```

### 6.2 入侵影响范围分析

如果 OpenClaw 被提示注入或渗透，最坏情况下：

```
┌──────────────────────────────────────────────────────────┐
│  可被影响的（损失可控）                                    │
│  ├── ~/mounts/nas-workspace/ 中的工作文件                │
│  ├── 当前会话上下文                                       │
│  └── Docker 沙箱内的临时文件                              │
├──────────────────────────────────────────────────────────┤
│  不可被影响的（隔离保护）                                  │
│  ├── ~/.openclaw/openclaw.json（宿主机，沙箱外）          │
│  ├── ~/.openclaw/.env（宿主机，沙箱外）                   │
│  ├── ~/.ssh/（宿主机，沙箱外）                            │
│  ├── NAS /openclaw-backup/（从未挂载，仅 SSH 可达）       │
│  ├── Mac Studio 系统文件（沙箱隔离）                      │
│  └── 其他 Mac Studio 用户数据（沙箱隔离）                 │
└──────────────────────────────────────────────────────────┘
```

### 6.3 入侵恢复流程

```
发现异常（日志告警 / 行为异常）
  │
  ├─► 1. 立即停止 OpenClaw
  │      launchctl stop com.openclaw.gateway
  │
  ├─► 2. 撤销所有 API 密钥
  │      Anthropic Console → 撤销 Key
  │      @BotFather → /revoke
  │
  ├─► 3. 检查工作区受损范围
  │      diff 备份与当前工作区
  │
  ├─► 4. 从 NAS 备份恢复
  │      scp ugreen-nas:/volume1/openclaw-backup/snapshots/latest.tar.gz /tmp/
  │      tar -xzf /tmp/latest.tar.gz -C ~/
  │
  ├─► 5. 轮换所有密钥
  │      运行 rotate-keys.sh
  │
  └─► 6. 审查 SOUL.md 和 MEMORY.md
         确认未被篡改，恢复后重启
```

---

## 七、安全架构总结

### 四层隔离

```
┌─────────────────────────────────────────────────────────────┐
│  层级 1：网络隔离                                            │
│  ├── Tailscale WireGuard 端到端加密，零公网端口              │
│  ├── 普通用户通过聊天平台 API 间接访问，不触碰基础设施       │
│  └── NAS 通过 Tailscale 仅与 Mac Studio 通信               │
├─────────────────────────────────────────────────────────────┤
│  层级 2：访问路径隔离                                        │
│  ├── 管理员 → Mac Studio（Tailscale SSH，身份认证）         │
│  ├── Mac Studio → NAS workspace（SMB，专用账户）            │
│  ├── NAS backup 仅管理员 SSH 可达，OpenClaw 不可见          │
│  └── 用户设备无需加入 tailnet，通过聊天 Bot 交互            │
├─────────────────────────────────────────────────────────────┤
│  层级 3：应用沙箱隔离                                        │
│  ├── OpenClaw 在 Docker 沙箱中运行                          │
│  ├── 沙箱仅挂载工作区，配置/密钥/备份均在沙箱外             │
│  ├── 沙箱默认断网，按需开启                                  │
│  └── 工具执行需人工审批（见 011 章）                         │
├─────────────────────────────────────────────────────────────┤
│  层级 4：密钥生命周期管理                                    │
│  ├── API 密钥定期轮换（建议 30 天）                         │
│  ├── 密钥以环境变量注入，不写入配置文件                      │
│  ├── 密钥泄露后可立即撤销，不影响系统架构                    │
│  └── 自动备份确保恢复能力                                   │
└─────────────────────────────────────────────────────────────┘
```

### 安全清单

```
□ Mac Studio 禁用休眠（pmset sleep 0）
□ Gateway 绑定 loopback（不暴露到 0.0.0.0）
□ Tailscale ACL deny-by-default，仅允许必要通信
□ NAS 工作区和备份区物理分离，不同权限
□ NAS 备份区不通过 SMB 共享，仅 SSH 可达
□ Mac Studio → NAS 使用 SSH 密钥认证
□ .env 文件权限 600
□ OpenClaw 沙箱 mode: "all"，默认 networkAccess: false
□ 沙箱仅挂载工作区，配置/密钥/备份不可见
□ Telegram 等平台设置 allowlist
□ API 密钥每 30 天轮换
□ 每日自动备份到 NAS 隔离备份区
□ 定期运行 openclaw security audit
□ 高风险操作配置人工审批（见 011 章）
□ 定期审查 Tailscale 设备列表，移除废弃设备
```

### 运维常用命令

```bash
# ── 状态检查 ──
tailscale status                         # Tailscale 网络状态
openclaw status                          # OpenClaw 服务状态
launchctl list | grep openclaw           # launchd 服务状态
mount | grep nas-workspace               # NAS 挂载状态

# ── 管理操作 ──
brew upgrade openclaw                    # 更新 OpenClaw
launchctl stop com.openclaw.gateway      # 停止服务
launchctl start com.openclaw.gateway     # 启动服务
~/.openclaw/scripts/rotate-keys.sh       # 轮换密钥
~/.openclaw/scripts/backup.sh            # 手动备份

# ── 安全审计 ──
openclaw security audit                  # 安全审计
openclaw logs --tail 100                 # 查看日志
ls -la ~/.openclaw/.env                  # 检查密钥文件权限
pmset -g                                 # 检查电源设置
```

---

## 下一步

- [009 - 故障排查与注意事项](009-troubleshooting.md)：常见问题的解决方法
- [011 - 高风险操作审批工作流](011-workflow-approval.md)：支付、组织管理等操作的人工审批配置

## 参考来源

- [Tailscale 文档 - ACL 访问控制](https://tailscale.com/kb/1018/acls/)
- [Tailscale 文档 - Serve](https://tailscale.com/kb/1312/serve/)
- [Tailscale 文档 - Funnel](https://tailscale.com/kb/1223/funnel/)
- [Tailscale 文档 - Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh/)
- [Tailscale 文档 - Docker 部署](https://tailscale.com/kb/1282/docker/)
- [Tailscale 文档 - 子网路由](https://tailscale.com/kb/1019/subnets/)
- [Apple 文档 - pmset 电源管理](https://ss64.com/mac/pmset.html)
- [OpenClaw 官方文档 - Tailscale 集成](https://docs.openclaw.ai/gateway/tailscale)
- [OpenClaw 官方文档 - Docker 沙箱](https://docs.openclaw.ai/install/docker)
- [Nebius - OpenClaw 安全架构](https://nebius.com/blog/posts/openclaw-security)
- [AI Maker - OpenClaw 安全加固三层指南](https://aimaker.substack.com/p/openclaw-security-hardening-guide)
