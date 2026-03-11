# 008 - 组网与远程沙箱配置

> 以 Mac Studio（中心节点）+ 绿联 NAS（资料库）+ Tailscale 为例，介绍多层隔离的家庭服务器部署方案。

## 架构设计思路

本方案的核心原则：**敏感资料永不直接暴露公网**。

- **Mac Studio** 作为 OpenClaw 中心节点，运行所有 ClawBot 实例
- **绿联 NAS** 作为资料库，仅接受来自 Mac Studio 的 SSH 访问
- **Tailscale** 组建私有网络，Mac Studio 通过 SSH 访问 NAS，可信设备通过 Tailscale 访问 Mac Studio

这样天然形成 **3 层隔离**：

```
第 1 层：公网隔离
  └── 无任何公网端口暴露，Tailscale P2P 加密隧道

第 2 层：访问路径隔离
  └── NAS 仅接受 Mac Studio 的内网 SSH，不可被 Tailscale 客户端直接访问

第 3 层：应用沙箱隔离
  └── OpenClaw 运行在 Docker 沙箱中，文件系统和网络受限
```

## 架构概览

```
                  Tailscale 私有网络（WireGuard 加密）
                  ┌───────────────────────────────────────────────┐
                  │                                               │
┌──────────┐      │    ┌────────────────────────┐                 │
│ MacBook  │◄─────┼───►│      Mac Studio        │                 │
│ (可信设备) │      │    │  ┌──────────────────┐  │                 │
│          │      │    │  │ OpenClaw 中心节点  │  │  SSH (仅内网)   │
└──────────┘      │    │  │ ClawBot 实例群    │  │◄───────────────►┤
                  │    │  └──────────────────┘  │                 │
┌──────────┐      │    │  Tailscale Serve (HTTPS)│  ┌──────────┐  │
│  iPhone  │◄─────┼───►│  (tailnet 内可信设备    │  │ 绿联 NAS │  │
│ (可信设备) │      │    │   才可访问)            │  │          │  │
└──────────┘      │    └────────────────────────┘  │ 资料库   │  │
                  │                                 │ 账户/    │  │
                  │                                 │ Workspace│  │
                  │                                 └──────────┘  │
                  └───────────────────────────────────────────────┘

公网用户 ────── ✗ ──────────── 无法直接访问 Mac Studio 或 NAS
```

---

## 一、Tailscale 组网

Tailscale 基于 WireGuard 协议，提供端到端加密的私有网络。**无需开放任何公网端口**。

### 1.1 注册 Tailscale

1. 访问 [tailscale.com](https://tailscale.com/) 注册账号
2. 免费版支持最多 100 台设备

### 1.2 在 Mac Studio 上安装

```bash
# Homebrew 安装
brew install --cask tailscale

# 启动并登录
sudo tailscale up
```

### 1.3 在绿联 NAS 上安装

绿联 NAS（UGOS）通过 Docker 安装 Tailscale：

```bash
# SSH 连接到 NAS（局域网 IP）
ssh root@192.168.1.100

# 拉取并运行 Tailscale 容器
docker run -d \
  --name tailscale \
  --hostname ugreen-nas \
  --restart always \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  -v /dev/net/tun:/dev/net/tun \
  -v /var/lib/tailscale:/var/lib/tailscale \
  --network host \
  tailscale/tailscale:latest

# 认证（按提示在浏览器完成）
docker exec tailscale tailscale up
```

> **注意**：NAS 加入 tailnet 仅用于让 Mac Studio 通过 Tailscale IP 访问，**不**对外开放 ClawBot 服务。如 NAS 支持应用商店安装 Tailscale，优先使用应用商店版本。

### 1.4 在 iPhone / MacBook 等可信设备上安装

从 App Store / Mac App Store 安装 Tailscale，登录同一账号即可加入 tailnet。

### 1.5 设置可信设备 ACL（Tailscale ACL）

在 [Tailscale 控制台](https://login.tailscale.com/admin/acls) 中配置设备访问规则，限制哪些设备可以访问 Mac Studio：

```json5
// tailscale ACL（示例）
{
  "acls": [
    // 允许可信设备访问 Mac Studio 的 OpenClaw 端口
    {
      "action": "accept",
      "src": ["tag:trusted-client"],
      "dst": ["tag:openclaw-server:18789"]
    },
    // Mac Studio 可以 SSH 访问 NAS
    {
      "action": "accept",
      "src": ["tag:openclaw-server"],
      "dst": ["tag:nas:22"]
    }
  ],
  "tagOwners": {
    "tag:trusted-client": ["autogroup:member"],
    "tag:openclaw-server": ["autogroup:owner"],
    "tag:nas": ["autogroup:owner"]
  }
}
```

### 1.6 验证组网

```bash
# 在 Mac Studio 上查看所有设备
tailscale status

# 预期输出：
# 100.x.x.1  mac-studio       your@email.com  macOS   -
# 100.x.x.2  ugreen-nas       your@email.com  linux   -
# 100.x.x.3  macbook          your@email.com  macOS   -

# 测试 Mac Studio → NAS 连通性
ping ugreen-nas
```

---

## 二、Mac Studio 安装 OpenClaw（中心节点）

Mac Studio 运行原生 macOS OpenClaw，作为 24/7 的服务中心。

### 2.1 安装 OpenClaw

```bash
brew tap openclaw/tap && brew install openclaw
```

### 2.2 设置为 launchd 系统服务（开机自启）

OpenClaw 引导向导会自动安装 launchd 服务，也可手动操作：

```bash
# 查看服务状态
launchctl list | grep openclaw

# 管理服务
launchctl start com.openclaw.gateway
launchctl stop  com.openclaw.gateway

# 设置登录后自动启动（推荐）
launchctl enable gui/$(id -u)/com.openclaw.gateway
```

### 2.3 配置 Mac Studio 作为服务器

创建或编辑 `~/.openclaw/openclaw.json`：

```json5
{
  // ── Gateway 服务器配置 ──
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "loopback",           // 仅绑定 127.0.0.1，通过 Tailscale Serve 对外
    "auth": {
      "mode": "tailscale",        // 使用 Tailscale 身份认证
      "allowTailscale": true
    }
  },

  // ── Tailscale 集成 ──
  "tailscale": {
    "mode": "serve",              // tailnet 内 HTTPS，不暴露公网
    "hostname": "mac-studio"      // tailnet 域名：mac-studio.your-tailnet.ts.net
  },

  // ── 代理默认设置 ──
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6",
      "api": "anthropic-messages",
      "sandbox": {
        "mode": "all",
        "docker": {
          "workspaceMount": "readwrite",
          "networkAccess": false      // 沙箱默认断网，按需开启
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
      "allowFrom": ["@your_telegram_username"]   // 仅允许自己
    }
  },

  // ── NAS 工作区挂载（通过 SSHFS）──
  "workspaces": {
    "nas-archive": {
      "type": "sshfs",
      "host": "ugreen-nas",        // Tailscale 主机名
      "remotePath": "/volume1/openclaw-workspace",
      "mountPoint": "~/mounts/nas-archive",
      "readonly": false
    }
  }
}
```

### 2.4 配置环境变量

```bash
# ~/.openclaw/.env（仅 owner 可读）
ANTHROPIC_API_KEY=sk-ant-your-key
TELEGRAM_BOT_TOKEN=123456789:ABCxxx
GATEWAY_PASSWORD=your-strong-password   # 备用密码认证
```

```bash
chmod 600 ~/.openclaw/.env
```

---

## 三、NAS 配置：资料库与账户管理

NAS 作为资料库，**不运行 OpenClaw**，只为 Mac Studio 提供存储空间和专用账户。

### 3.1 在 NAS 上创建 OpenClaw 专用账户

在绿联 NAS 管理界面（UGOS）中：

1. **用户管理** → 新建用户 `openclaw-agent`
2. 设置强密码（或仅允许 SSH 密钥登录）
3. **权限** → 仅授予特定共享文件夹的读写权限

```bash
# 在 NAS 上为 openclaw-agent 创建专用工作区目录
mkdir -p /volume1/openclaw-workspace/{projects,archives,uploads}
chown -R openclaw-agent:users /volume1/openclaw-workspace
chmod 750 /volume1/openclaw-workspace
```

### 3.2 Mac Studio 通过 SSH 密钥访问 NAS

```bash
# 在 Mac Studio 上生成 SSH 密钥（如尚未生成）
ssh-keygen -t ed25519 -C "openclaw-agent@mac-studio" -f ~/.ssh/id_nas

# 将公钥上传到 NAS
ssh-copy-id -i ~/.ssh/id_nas.pub openclaw-agent@ugreen-nas

# 测试连接
ssh -i ~/.ssh/id_nas openclaw-agent@ugreen-nas "echo 连接成功"
```

配置 `~/.ssh/config`，简化连接：

```
Host ugreen-nas
    HostName ugreen-nas          # Tailscale 主机名
    User openclaw-agent
    IdentityFile ~/.ssh/id_nas
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 3.3 通过 SSHFS 挂载 NAS 工作区

```bash
# 安装 SSHFS
brew install --cask macfuse
brew install sshfs

# 挂载 NAS 工作区
mkdir -p ~/mounts/nas-archive
sshfs ugreen-nas:/volume1/openclaw-workspace ~/mounts/nas-archive \
  -o reconnect,ServerAliveInterval=15,IdentityFile=~/.ssh/id_nas

# 设置开机自动挂载（通过 launchd）
```

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
    <string>/usr/local/bin/sshfs</string>
    <string>ugreen-nas:/volume1/openclaw-workspace</string>
    <string>/Users/YOUR_USER/mounts/nas-archive</string>
    <string>-o</string>
    <string>reconnect,ServerAliveInterval=15,IdentityFile=/Users/YOUR_USER/.ssh/id_nas</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.openclaw.nas-mount.plist
```

---

## 四、可信设备访问 Mac Studio

可信设备（MacBook、iPhone）通过 Tailscale 访问 Mac Studio 上的 OpenClaw 服务。

### 4.1 访问控制面板（Tailscale Serve）

在加入 tailnet 的设备上，直接访问：

```
https://mac-studio.your-tailnet.ts.net
```

Tailscale Serve 提供 tailnet 内的 HTTPS 访问，不暴露公网。

### 4.2 SSH 访问 Mac Studio

可信设备可通过 Tailscale SSH 管理 Mac Studio：

```bash
# 开启 Tailscale SSH（在 Mac Studio 上执行一次）
sudo tailscale up --ssh

# 从 MacBook 连接
ssh your-username@mac-studio
```

### 4.3 SSH 隧道访问（备用方案）

如果不使用 Tailscale Serve，可通过 SSH 隧道：

```bash
# 在 MacBook 上建立隧道
ssh -L 18789:localhost:18789 your-username@mac-studio

# 然后访问 http://localhost:18789
```

### 4.4 Tailscale Funnel（不推荐，仅 Webhook 等特殊场景）

> **⚠️ 警告**：Funnel 会将服务暴露到公网。只有需要接收 Webhook 回调等特殊情况才考虑使用，且必须配合强密码认证。

```json5
{
  "tailscale": {
    "mode": "funnel"   // 公网 HTTPS
  },
  "gateway": {
    "auth": {
      "mode": "password"   // 必须开启密码认证
    }
  }
}
```

---

## 五、安全架构总结

### 隔离层级

```
┌─────────────────────────────────────────────────────────────┐
│  层级 1：网络隔离                                            │
│  ├── Tailscale WireGuard P2P 加密，零公网端口               │
│  └── NAS 通过 Tailscale IP 只与 Mac Studio 通信             │
├─────────────────────────────────────────────────────────────┤
│  层级 2：访问路径隔离                                        │
│  ├── 可信设备 → Mac Studio（Tailscale Serve / SSH）         │
│  ├── Mac Studio → NAS（SSH 密钥，专用账户，SSHFS 挂载）      │
│  └── NAS 对可信客户端不可见，无法被直接连接                  │
├─────────────────────────────────────────────────────────────┤
│  层级 3：应用沙箱隔离                                        │
│  ├── OpenClaw 在 Docker 沙箱中运行                          │
│  ├── 沙箱默认断网，按需开启                                  │
│  └── 工具执行需要人工审批（见第 011 章）                     │
└─────────────────────────────────────────────────────────────┘
```

### 安全清单

```
□ Mac Studio Gateway 绑定 loopback（不暴露到 0.0.0.0）
□ Tailscale ACL 限制可信设备范围
□ NAS 专用账户仅有最小权限（不能 SSH 到其他路径）
□ Mac Studio → NAS 使用 SSH 密钥认证（禁用密码登录）
□ .env 文件权限 600
□ OpenClaw 沙箱默认 networkAccess: false
□ Telegram/通讯平台设置 allowlist，仅允许自己
□ 定期审查 Tailscale 设备列表，移除不再使用的设备
□ 定期运行 openclaw security audit
□ 高风险操作配置人工审批（见 011 章）
```

### 运维常用命令

```bash
# 查看 OpenClaw 服务状态
launchctl list | grep openclaw
openclaw status

# 更新 OpenClaw
brew upgrade openclaw
launchctl stop com.openclaw.gateway && launchctl start com.openclaw.gateway

# 备份配置
tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz ~/.openclaw/

# 检查 NAS 挂载状态
mount | grep nas-archive
ls ~/mounts/nas-archive

# 安全审计
openclaw security audit
openclaw logs --tail 100
```

---

## 下一步

- [009 - 故障排查与注意事项](009-troubleshooting.md)：常见问题的解决方法
- [011 - 高风险操作审批工作流](011-workflow-approval.md)：支付、组织管理等操作的人工审批配置

## 参考来源

- [OpenClaw 官方文档 - Tailscale 集成](https://docs.openclaw.ai/gateway/tailscale)
- [Mager.co - OpenClaw + Mac Studio + Tailscale 始终在线方案](https://www.mager.co/blog/2026-02-22-openclaw-mac-mini-tailscale/)
- [Tailscale 文档 - ACL 访问控制](https://tailscale.com/kb/1018/acls/)
- [Tailscale 文档 - Serve 与 Funnel](https://tailscale.com/kb/1242/tailscale-serve/)
- [OpenClaw Blog - SSH 和 Tailscale 远程访问](https://openclawblog.space/articles/remote-openclaw-access-with-ssh-and-tailscale-a-practical-guide)
- [AI Maker - OpenClaw 安全加固三层指南](https://aimaker.substack.com/p/openclaw-security-hardening-guide)
- [Nebius - OpenClaw 安全架构](https://nebius.com/blog/posts/openclaw-security)
