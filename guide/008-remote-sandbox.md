# 008 - 组网与远程沙箱配置

> 以绿联 NAS + macOS + Tailscale 为例，介绍远程部署和安全访问 OpenClaw 的完整方案。

## 为什么需要远程部署？

将 OpenClaw 部署在独立设备上的好处：

- **24/7 运行**：不受个人电脑开关机影响
- **安全隔离**：代理运行在独立设备上，不直接接触日常工作机
- **随处访问**：通过 Tailscale 从任何设备安全访问
- **资源独占**：不影响工作机的性能

## 架构概览

```
                  Tailscale 私有网络（WireGuard 加密）
                  ┌─────────────────────────────────────┐
                  │                                     │
┌─────────┐       │    ┌──────────────┐                  │
│ MacBook │◄──────┼───►│ 绿联 NAS     │                  │
│ (客户端) │       │    │ (Docker +    │                  │
│         │       │    │  OpenClaw)   │                  │
└─────────┘       │    └──────────────┘                  │
                  │                                     │
┌─────────┐       │    ┌──────────────┐                  │
│  iPhone │◄──────┼───►│  Mac Mini    │                  │
│ (移动端) │       │    │ (可选备用)    │                  │
└─────────┘       │    └──────────────┘                  │
                  └─────────────────────────────────────┘
```

---

## 一、Tailscale 组网

Tailscale 基于 WireGuard 协议，提供端到端加密的私有网络。设备之间直接点对点连接，**无需暴露任何公网端口**。

### 1.1 注册 Tailscale

1. 访问 [tailscale.com](https://tailscale.com/)
2. 使用 Google / Microsoft / GitHub 账号登录
3. 免费版支持最多 100 台设备，个人使用完全足够

### 1.2 在 macOS 上安装

```bash
# Homebrew
brew install --cask tailscale

# 或从 Mac App Store 安装
```

启动 Tailscale 并登录：

```bash
# 命令行登录
sudo tailscale up

# 或通过菜单栏图标登录
```

### 1.3 在绿联 NAS 上安装

绿联 NAS（UGOS 系统）支持 Docker，可以通过 Docker 安装 Tailscale：

```bash
# SSH 连接到 NAS
ssh root@192.168.1.100    # 替换为你的 NAS 局域网 IP

# 拉取 Tailscale Docker 镜像
docker pull tailscale/tailscale:latest

# 运行 Tailscale 容器
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

# 认证
docker exec tailscale tailscale up
# 按提示在浏览器中完成认证
```

> **如果 NAS 支持应用商店安装 Tailscale**，优先使用应用商店版本。

### 1.4 验证组网

```bash
# 在 macOS 上查看 tailnet 中的设备
tailscale status

# 预期输出类似：
# 100.x.x.1  macbook          your-email@...  macOS   -
# 100.x.x.2  ugreen-nas       your-email@...  linux   -

# 测试连通性
ping ugreen-nas    # 使用 Tailscale 主机名
```

---

## 二、在绿联 NAS 上部署 OpenClaw

### 2.1 创建 OpenClaw 目录

```bash
# SSH 到 NAS
ssh root@ugreen-nas    # 通过 Tailscale 主机名连接

# 创建目录
mkdir -p /volume1/docker/openclaw/config
mkdir -p /volume1/docker/openclaw/workspace
```

### 2.2 使用 Docker Compose 部署

创建 `/volume1/docker/openclaw/docker-compose.yml`：

```yaml
version: "3.8"

services:
  openclaw:
    image: alpine/openclaw:latest
    container_name: openclaw
    restart: always
    ports:
      - "127.0.0.1:18789:18789"    # 仅绑定到 loopback
    volumes:
      - ./config:/root/.openclaw
      - ./workspace:/workspace
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - TZ=Asia/Shanghai
    networks:
      - openclaw-net

networks:
  openclaw-net:
    driver: bridge
```

创建 `.env` 文件：

```bash
# /volume1/docker/openclaw/.env
ANTHROPIC_API_KEY=sk-ant-your-key
TELEGRAM_BOT_TOKEN=123456789:ABCxxx
```

> **安全提示**：`.env` 文件权限设为仅 root 可读：`chmod 600 .env`

### 2.3 配置 OpenClaw

创建 `/volume1/docker/openclaw/config/openclaw.json`：

```json5
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "loopback",       // 不暴露到网络
    "auth": {
      "mode": "password",
      "password": "${GATEWAY_PASSWORD}"
    }
  },

  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-6",
      "api": "anthropic-messages",
      "sandbox": {
        "mode": "all",
        "docker": {
          "workspaceMount": "readwrite",
          "networkAccess": true
        }
      }
    }
  },

  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": ["@your_telegram_username"]
    }
  }
}
```

### 2.4 启动

```bash
cd /volume1/docker/openclaw
docker compose up -d

# 查看日志
docker compose logs -f openclaw
```

---

## 三、Tailscale 与 OpenClaw 集成

### 3.1 Tailscale Serve（推荐）

Tailscale Serve 在 tailnet 内部提供 HTTPS 访问，Gateway 保持绑定在 loopback：

```json5
// openclaw.json
{
  "gateway": {
    "bind": "loopback"
  },
  "tailscale": {
    "mode": "serve"     // tailnet-only HTTPS
  }
}
```

开启后，可以在 tailnet 中通过 `https://ugreen-nas.your-tailnet.ts.net` 访问 OpenClaw 控制面板。

### 3.2 Tailscale 身份认证

当 `tailscale.mode = "serve"` 时，可以使用 Tailscale 身份替代密码认证：

```json5
{
  "gateway": {
    "auth": {
      "allowTailscale": true    // 使用 Tailscale 身份认证
    }
  }
}
```

OpenClaw 会通过 `tailscale whois` 验证连接者的 Tailscale 身份。

### 3.3 Tailscale Funnel（公网访问 — 不推荐）

如果确实需要公网访问（如 Webhook 回调）：

```json5
{
  "tailscale": {
    "mode": "funnel"    // 公网 HTTPS
  },
  "gateway": {
    "auth": {
      "mode": "password"    // Funnel 模式强制要求密码
    }
  }
}
```

> **⚠️ 警告**：`funnel` 模式如果 auth 不是 `password` 模式会拒绝启动，防止公网无认证暴露。

---

## 四、通过 SSH 远程管理

### 4.1 SSH over Tailscale

Tailscale 的 SSH 是 WireGuard 端到端加密的：

```bash
# 在 macOS 上通过 Tailscale SSH 连接 NAS
ssh root@ugreen-nas

# 开启 Tailscale SSH（可选，替代传统 SSH）
# 在 NAS 上：
tailscale up --ssh
```

### 4.2 SSH 端口转发访问控制面板

如果不使用 Tailscale Serve，可以通过 SSH 隧道访问：

```bash
# 建立 SSH 隧道
ssh -L 18789:localhost:18789 root@ugreen-nas

# 然后在本地浏览器访问 http://localhost:18789
```

---

## 五、Mac Mini 作为备用节点

如果你有闲置的 Mac Mini，可以作为备用/互补节点：

### 5.1 macOS 上安装 OpenClaw（原生）

```bash
brew tap openclaw/tap && brew install openclaw
```

### 5.2 设置为系统服务

OpenClaw 的引导向导会自动将 Gateway 安装为 launchd 服务：

```bash
# 查看服务状态
launchctl list | grep openclaw

# 手动管理
launchctl start com.openclaw.gateway
launchctl stop com.openclaw.gateway
```

### 5.3 始终在线

Mac Mini 的优势：

- 原生 macOS 运行，性能无损
- 低功耗，适合 24/7 运行
- 支持 iMessage 等 macOS 专属通道
- 通过 Tailscale 随处访问

---

## 六、安全加固

### 纵深防御架构

```
第 1 层：网络隔离
  └── Tailscale 私有网络，零公网端口

第 2 层：认证
  └── Tailscale 身份认证 或 密码认证

第 3 层：应用隔离
  └── Docker 沙箱，限制文件系统和网络

第 4 层：权限控制
  └── 工具 allow/deny，执行审批
```

### 安全清单

```
□ Gateway 绑定到 loopback（不暴露到 0.0.0.0）
□ 所有访问通过 Tailscale（零公网端口）
□ 通讯平台设置 allowlist
□ 敏感凭据存储在宿主机，不在容器中
□ 定期运行 openclaw security audit
□ NAS .env 文件权限 600
□ 定期审查 Tailscale 设备列表
□ 禁用不使用的 Tailscale funnel 节点
□ SSH 密钥认证（禁用密码登录）
```

### 运维建议

```bash
# 定期更新
docker compose pull && docker compose up -d

# 备份配置
tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz /volume1/docker/openclaw/config/

# 检查日志
docker compose logs --tail 100 openclaw

# 安全审计
docker exec openclaw openclaw security audit
```

## 下一步

进入 [009 - 故障排查与注意事项](009-troubleshooting.md) 了解常见问题的解决方法。

## 参考来源

- [OpenClaw 官方文档 - Tailscale](https://docs.openclaw.ai/gateway/tailscale)
- [Medium - 零公网端口部署 OpenClaw](https://alirezarezvani.medium.com/i-deployed-openclaw-with-zero-public-ports-here-is-the-tailscale-setup-that-actually-works-86f8c9e6f158)
- [Mager.co - OpenClaw + Mac Mini + Tailscale 始终在线](https://www.mager.co/blog/2026-02-22-openclaw-mac-mini-tailscale/)
- [AI Maker - OpenClaw 安全加固三层指南](https://aimaker.substack.com/p/openclaw-security-hardening-guide)
- [Nebius - OpenClaw 安全架构](https://nebius.com/blog/posts/openclaw-security)
- [OpenClaw Blog - SSH 和 Tailscale 远程访问](https://openclawblog.space/articles/remote-openclaw-access-with-ssh-and-tailscale-a-practical-guide)
