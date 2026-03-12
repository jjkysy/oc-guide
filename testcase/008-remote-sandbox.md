# 测试用例：008 - 组网与远程沙箱

> 对应指南 [008 - 组网与远程沙箱配置](../guide/008-remote-sandbox.md)
>
> **架构前提**：Mac Studio 为 OpenClaw 中心节点，绿联 NAS 为资料库，Tailscale 组建私有网络。

---

## TC-008-01：Mac Studio 24/7 服务器配置

**操作步骤**：
1. 执行 `pmset -g` 查看电源设置
2. 确认 `sleep`、`disksleep` 值为 0
3. 确认 `autorestart` 值为 1

**测试目标**：验证 Mac Studio 不会自动休眠，掉电后能自动重启

**预期结果**：
- `sleep 0`（永不休眠）
- `disksleep 0`（磁盘不休眠）
- `autorestart 1`（掉电自动重启）
- `womp 1`（网络唤醒已开启）

---

## TC-008-02：Tailscale 组网验证

**操作步骤**：
1. 在 Mac Studio 上执行 `tailscale status`
2. 在管理员 MacBook 上执行 `tailscale status`
3. 从 Mac Studio 执行 `ping ugreen-nas`

**测试目标**：验证所有设备均加入同一 tailnet

**预期结果**：
- `tailscale status` 列出所有设备，各有 `100.x.x.x` 地址
- Mac Studio 能 ping 通 `ugreen-nas`
- MacBook 能 ping 通 `mac-studio`

---

## TC-008-03：Tailscale ACL 访问控制验证

**操作步骤**：
1. 从管理员 MacBook（`tag:admin`）SSH 到 Mac Studio
2. 从管理员 MacBook 访问 `https://mac-studio.your-tailnet.ts.net`
3. 从未授权设备尝试 SSH 到 Mac Studio
4. 从管理员 MacBook 尝试直接 SMB 连接 NAS（应被 ACL 拒绝，除非有 `tag:admin` → NAS 规则）

**测试目标**：验证 ACL deny-by-default 生效，仅允许授权通信

**预期结果**：
- 管理员设备可 SSH 和 HTTPS 访问 Mac Studio
- 未授权设备连接超时或被拒绝
- ACL 规则严格按标签匹配

---

## TC-008-04：OpenClaw 服务启动与绑定

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

## TC-008-05：Docker 沙箱隔离验证（核心安全测试）

**操作步骤**：
1. 通过 Telegram 让 OpenClaw 执行 `cat ~/.openclaw/.env`
2. 通过 Telegram 让 OpenClaw 执行 `ls ~/.ssh/`
3. 通过 Telegram 让 OpenClaw 执行 `ls ~/mounts/nas-workspace/`
4. 通过 Telegram 让 OpenClaw 尝试写入 `/etc/hosts`

**测试目标**：验证沙箱仅允许访问工作区，配置/密钥/系统文件不可达

**预期结果**：
- 读取 `.env` 失败（文件在沙箱外，不存在）
- 读取 `~/.ssh/` 失败（目录在沙箱外）
- 读取工作区成功，能列出 `projects/`、`archives/`、`uploads/`
- 写入系统文件失败（权限不足）

---

## TC-008-06：NAS SMB 挂载验证

**操作步骤**：
1. 执行 `mount | grep nas-workspace`
2. 执行 `ls ~/mounts/nas-workspace`
3. 在 Mac Studio 上在挂载目录创建测试文件，在 NAS 上验证文件存在

**测试目标**：验证 NAS 工作区通过 SMB 挂载到 Mac Studio

**预期结果**：
- 挂载目录出现在 `mount` 输出中，类型为 `smbfs`
- 能列出 NAS 上的文件（`projects/`、`archives/`、`uploads/`）
- Mac Studio 写入的文件在 NAS 上可见

---

## TC-008-07：NAS 备份区隔离验证

**操作步骤**：
1. 确认 `openclaw-backup` 没有 SMB 共享：在 NAS 管理界面检查
2. 通过 Telegram 让 OpenClaw 尝试访问 NAS 备份路径
3. 管理员通过 SSH 验证备份区可达：`ssh ugreen-nas "ls /volume1/openclaw-backup/"`

**测试目标**：验证备份区仅管理员可达，OpenClaw 完全不可见

**预期结果**：
- NAS 管理界面中 `openclaw-backup` 不在 SMB 共享列表
- OpenClaw 无法触及备份区任何文件
- 管理员 SSH 可正常访问备份区

---

## TC-008-08：Tailscale Serve HTTPS 访问

**操作步骤**：
1. 在 Mac Studio 上执行 `tailscale serve 18789`
2. 在管理员 MacBook 上访问 `https://mac-studio.your-tailnet.ts.net`
3. 在未加入 tailnet 的设备上尝试访问同一地址

**测试目标**：验证 Tailscale Serve 提供 tailnet 内 HTTPS，不暴露公网

**预期结果**：
- 管理员设备可通过 HTTPS 访问 OpenClaw 控制面板
- TLS 证书由 Tailscale 自动签发
- tailnet 外设备无法访问（连接超时）

---

## TC-008-09：开机自启全链路验证

**操作步骤**：
1. 重启 Mac Studio
2. 等待 2 分钟系统完全启动
3. 执行 `tailscale status`
4. 执行 `openclaw status`
5. 执行 `mount | grep nas-workspace`

**测试目标**：验证重启后 Tailscale、OpenClaw、NAS 挂载自动恢复

**预期结果**：
- Tailscale 自动连接（`tailscale status` 显示在线）
- OpenClaw Gateway 自动启动
- NAS 工作区挂载自动恢复（LaunchAgent 等待 Tailscale 就绪后挂载）

---

## TC-008-10：密钥文件安全验证

**操作步骤**：
1. 执行 `ls -la ~/.openclaw/.env`
2. 执行 `stat -f "%Sp" ~/.openclaw/.env`
3. 检查 .env 中的密钥是否以环境变量引用方式出现在 openclaw.json 中

**测试目标**：验证密钥文件权限和引用方式安全

**预期结果**：
- `.env` 权限为 `-rw-------`（600）
- `openclaw.json` 中密钥使用 `${VAR_NAME}` 引用，不含明文
- `.env` 文件 owner 为当前用户

---

## TC-008-11：自动备份验证

**操作步骤**：
1. 手动执行 `~/.openclaw/scripts/backup.sh`
2. SSH 到 NAS 检查备份文件：`ssh ugreen-nas "ls -la /volume1/openclaw-backup/snapshots/"`
3. 验证备份内容：下载并解压检查

**测试目标**：验证备份脚本正常工作，备份到 NAS 隔离区

**预期结果**：
- 备份脚本执行成功，无错误
- NAS 备份区生成 `openclaw-YYYYMMDD-HHMMSS.tar.gz` 文件
- 备份包含 `openclaw.json`、`agents/`、`skills/` 等关键文件
- 备份不包含日志和会话缓存

---

## TC-008-12：多角色消息通讯

**前置条件**：Mac Studio 上 OpenClaw + Telegram 已配置，allowlist 包含管理员和普通用户

**操作步骤**：
1. 管理员通过 Telegram 发送消息给 Bot
2. 普通用户（家人）通过 Telegram 发送消息给 Bot
3. 不在 allowlist 中的用户尝试发送消息
4. 让 Bot 读取工作区中的文件

**测试目标**：验证多角色访问控制和文件操作

**预期结果**：
- 管理员和已授权用户能与 Bot 正常对话
- 未授权用户消息被忽略
- Bot 能读取 `~/mounts/nas-workspace` 下的文件
- Bot 无法读取沙箱外的文件
