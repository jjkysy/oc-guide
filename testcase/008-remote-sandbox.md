# 测试用例：008 - 组网与远程沙箱

> 对应指南 [008 - 组网与远程沙箱配置](../guide/008-remote-sandbox.md)

## TC-008-01：Tailscale 组网

**操作步骤**：
1. 在 macOS 上安装并登录 Tailscale
2. 在 NAS 上通过 Docker 安装并登录 Tailscale
3. 执行 `tailscale status`

**测试目标**：验证 Tailscale 私有网络建立

**预期结果**：
- 两台设备都出现在 tailnet 中
- 各自有 100.x.x.x 的 Tailscale IP
- 可通过主机名互 ping

---

## TC-008-02：NAS Docker 部署

**前置条件**：NAS 上 Docker 和 Tailscale 已就绪

**操作步骤**：
1. SSH 到 NAS：`ssh root@ugreen-nas`
2. 创建 OpenClaw 目录和配置文件
3. 执行 `docker compose up -d`
4. 执行 `docker compose logs -f openclaw`

**测试目标**：验证 NAS 上 Docker 部署

**预期结果**：
- 容器正常启动，状态为 `Up`
- 日志中无错误
- Gateway 监听在 127.0.0.1:18789

---

## TC-008-03：Tailscale Serve

**前置条件**：OpenClaw 在 NAS 上运行

**操作步骤**：
1. 配置 `tailscale.mode` 为 `serve`
2. 在 macOS 上访问 `https://ugreen-nas.your-tailnet.ts.net`

**测试目标**：验证 Tailscale Serve 提供 HTTPS 访问

**预期结果**：
- 在 tailnet 内可通过 HTTPS 访问控制面板
- 连接经 WireGuard 加密
- tailnet 外无法访问

---

## TC-008-04：Tailscale 身份认证

**操作步骤**：
1. 配置 `gateway.auth.allowTailscale` 为 `true`
2. 从 tailnet 中的设备访问 Gateway

**测试目标**：验证免密码 Tailscale 身份认证

**预期结果**：
- 无需输入密码或 token
- 身份通过 Tailscale 验证
- 日志中显示认证来源为 Tailscale

---

## TC-008-05：SSH 隧道远程访问

**操作步骤**：
1. 在 macOS 上执行 `ssh -L 18789:localhost:18789 root@ugreen-nas`
2. 打开浏览器访问 `http://localhost:18789`

**测试目标**：验证 SSH 隧道访问 Gateway

**预期结果**：
- SSH 连接成功建立
- 浏览器能访问 Gateway 控制面板
- 关闭 SSH 后访问中断

---

## TC-008-06：跨设备消息通讯

**前置条件**：NAS 上 OpenClaw + Telegram 已配置

**操作步骤**：
1. 在 macOS 上通过 Telegram 发送消息给 Bot
2. 在 iPhone 上通过 Telegram 发送消息给 Bot

**测试目标**：验证 NAS 部署后多设备访问

**预期结果**：
- 两个设备都能正常与 Bot 对话
- 会话上下文保持连贯
- 响应延迟在可接受范围内（< 10 秒）

---

## TC-008-07：安全加固验证

**操作步骤**：
1. 确认 Gateway 绑定到 loopback：`docker exec openclaw netstat -tlnp | grep 18789`
2. 从 NAS 局域网 IP 尝试访问 18789 端口
3. 确认 `.env` 文件权限：`ls -la .env`
4. 运行 `docker exec openclaw openclaw security audit`

**测试目标**：验证安全加固配置

**预期结果**：
- Gateway 仅监听 127.0.0.1:18789
- 局域网 IP 无法直接访问
- `.env` 权限为 `-rw-------`（600）
- 安全审计无严重问题

---

## TC-008-08：备份与恢复

**操作步骤**：
1. 执行备份：`tar -czf backup.tar.gz /volume1/docker/openclaw/config/`
2. 停止容器：`docker compose down`
3. 删除配置目录
4. 恢复备份：`tar -xzf backup.tar.gz`
5. 重新启动：`docker compose up -d`

**测试目标**：验证备份恢复流程

**预期结果**：
- 恢复后 OpenClaw 正常启动
- 配置、记忆、SOUL 全部恢复
- 通讯平台正常连接
