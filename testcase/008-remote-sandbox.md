# 测试用例：008 - 组网与远程沙箱

> 对应指南 [008 - 组网与远程沙箱配置](../guide/008-remote-sandbox.md)
>
> **架构前提**：Mac Studio 为 OpenClaw 中心节点，绿联 NAS 为资料库，Tailscale 组建私有网络。

---

## TC-008-01：Tailscale 组网验证

**操作步骤**：
1. 在 Mac Studio 上执行 `tailscale status`
2. 在 MacBook（可信设备）上执行 `tailscale status`
3. 从 Mac Studio 执行 `ping ugreen-nas`

**测试目标**：验证三台设备（Mac Studio、NAS、MacBook）均加入同一 tailnet

**预期结果**：
- `tailscale status` 列出所有设备，各有 `100.x.x.x` 地址
- Mac Studio 能 ping 通 `ugreen-nas`
- MacBook 能 ping 通 `mac-studio`

---

## TC-008-02：Tailscale ACL 访问控制验证

**操作步骤**：
1. 从 MacBook 尝试访问 `https://mac-studio.your-tailnet.ts.net`
2. 从未加入 tailnet 的设备尝试访问同一地址

**测试目标**：验证只有 `tag:trusted-client` 设备可访问 Mac Studio 的 OpenClaw 服务

**预期结果**：
- 可信设备能正常访问控制面板
- 未加入 tailnet 或不在 ACL 中的设备无法访问

---

## TC-008-03：Mac Studio OpenClaw 服务启动

**操作步骤**：
1. 执行 `launchctl list | grep openclaw`
2. 执行 `openclaw status`
3. 执行 `lsof -i :18789`

**测试目标**：验证 OpenClaw 以 launchd 服务形式运行，绑定正确地址

**预期结果**：
- launchctl 列出 `com.openclaw.gateway`，状态为运行
- Gateway 监听在 `127.0.0.1:18789`（非 `0.0.0.0:18789`）
- `openclaw status` 无错误

---

## TC-008-04：Mac Studio → NAS SSH 密钥访问

**操作步骤**：
1. 在 Mac Studio 上执行 `ssh ugreen-nas "echo 连接成功"`
2. 检查不使用密钥是否被拒绝：`ssh -o PasswordAuthentication=no -o PubkeyAuthentication=no openclaw-agent@ugreen-nas`

**测试目标**：验证 Mac Studio 通过 SSH 密钥访问 NAS 专用账户，禁用密码登录

**预期结果**：
- 密钥登录成功，输出"连接成功"
- 密码登录被拒绝（`Permission denied`）

---

## TC-008-05：NAS 工作区 SSHFS 挂载

**操作步骤**：
1. 执行 `mount | grep nas-archive`
2. 执行 `ls ~/mounts/nas-archive`
3. 在 Mac Studio 上在挂载目录创建测试文件，在 NAS 上验证文件存在

**测试目标**：验证 NAS 工作区通过 SSHFS 挂载到 Mac Studio

**预期结果**：
- 挂载目录出现在 `mount` 输出中
- 能列出 NAS 上的文件（`projects/`, `archives/`, `uploads/`）
- Mac Studio 写入的文件在 NAS 上可见

---

## TC-008-06：Tailscale Serve HTTPS 访问

**操作步骤**：
1. 在 MacBook 上访问 `https://mac-studio.your-tailnet.ts.net`
2. 在 iPhone 上访问同一地址（已加入 tailnet）
3. 在未加入 tailnet 的设备上尝试访问

**测试目标**：验证 Tailscale Serve 提供 tailnet 内 HTTPS，不暴露公网

**预期结果**：
- 可信设备可通过 HTTPS 访问 OpenClaw 控制面板
- 连接经 WireGuard 加密
- tailnet 外设备无法访问（连接超时）

---

## TC-008-07：NAS 隔离验证（核心安全测试）

**操作步骤**：
1. 从 MacBook 直接尝试 SSH 到 NAS：`ssh openclaw-agent@ugreen-nas`
2. 从公网设备尝试访问 NAS 任意端口

**测试目标**：验证 NAS 不可被可信客户端直接访问，仅 Mac Studio 可通过 SSH 访问

**预期结果**：
- MacBook 直接 SSH NAS 被 Tailscale ACL 拒绝（依据 ACL 配置）
- 公网无法访问 NAS（连接超时）
- 只有通过 Mac Studio 才能间接操作 NAS 上的文件

---

## TC-008-08：开机自启验证

**操作步骤**：
1. 重启 Mac Studio
2. 等待系统完全启动后，执行 `openclaw status`
3. 执行 `mount | grep nas-archive`

**测试目标**：验证 OpenClaw 服务和 SSHFS 挂载在重启后自动恢复

**预期结果**：
- OpenClaw Gateway 自动启动
- NAS 工作区挂载自动恢复
- 无需手动干预

---

## TC-008-09：安全配置全面检查

**操作步骤**：
1. 运行 `bash scripts/health-check.sh`
2. 执行 `openclaw security audit`
3. 检查 `~/.openclaw/.env` 权限：`ls -la ~/.openclaw/.env`
4. 验证 NAS 专用账户权限范围

**测试目标**：验证所有安全加固配置到位

**预期结果**：
- health-check 全部 PASS，无 FAIL
- 安全审计无严重问题
- `.env` 权限为 `600`
- NAS `openclaw-agent` 账户只能访问指定工作区目录

---

## TC-008-10：多设备消息通讯

**前置条件**：Mac Studio 上 OpenClaw + Telegram 已配置

**操作步骤**：
1. 在 MacBook 上通过 Telegram 发送消息给 Bot
2. 在 iPhone 上通过 Telegram 发送消息给 Bot
3. 请 Bot 读取 NAS 工作区中的一个文件（通过 SSHFS 挂载路径）

**测试目标**：验证多设备访问和 NAS 文件操作

**预期结果**：
- 两个设备都能与 Bot 正常对话
- Bot 能读取 `~/mounts/nas-archive` 下的文件
- 会话上下文连贯，响应延迟 < 15 秒
