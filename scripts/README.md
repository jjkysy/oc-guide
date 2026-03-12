# scripts/ - 便捷脚本

> OpenClaw 安装、维护、安全验证和测试用的自动化脚本。

## 脚本列表

| 脚本 | 用途 | 对应指南 |
|------|------|----------|
| `install.sh` | macOS 快速安装 | 001 |
| `setup-server.sh` | Mac Studio 24/7 服务器配置向导 | 008 |
| `backup.sh` | 配置备份（本地 + NAS 远程） | 008 |
| `health-check.sh` | 运行状态与安全健康检查 | 全局 |
| `rotate-keys.sh` | API 密钥检查与轮换 | 008 |
| `verify-sandbox.sh` | 沙箱隔离安全验证 | 008 |
| `test-008.sh` | 008 章节全部测试用例自动化 | 008 |

---

## install.sh

一键安装 OpenClaw，支持三种安装方式。

```bash
# 交互式选择
bash scripts/install.sh

# 直接指定
bash scripts/install.sh homebrew    # 推荐
bash scripts/install.sh npm
bash scripts/install.sh docker
```

**功能**：
- 自动检测 macOS 版本和芯片架构
- 安装完成后自动运行 `openclaw doctor` 诊断
- npm 安装自动处理权限问题（避免 sudo）

---

## setup-server.sh

Mac Studio 24/7 服务器一站式配置向导。交互式引导完成所有 008 章节的基础配置。

```bash
bash scripts/setup-server.sh
```

**配置流程**：
1. 电源管理（禁用休眠、掉电自动重启）
2. Tailscale 安装与认证
3. NAS SSH 密钥生成与上传
4. NAS SMB 挂载与自动挂载 LaunchAgent
5. OpenClaw 安装与 .env 密钥配置
6. 自动备份 cron 配置

**对应测试用例**：TC-008-01, TC-008-04, TC-008-09

---

## backup.sh

备份 `~/.openclaw/` 中的配置、记忆和代理文件。支持本地和 NAS 远程备份。

```bash
# 本地备份（默认 ~/openclaw-backups/）
bash scripts/backup.sh

# 指定本地备份目录
bash scripts/backup.sh --local /path/to/backups

# 备份到 NAS 隔离备份区（通过 SSH）
bash scripts/backup.sh --nas
```

**功能**：
- 自动排除日志和临时会话文件
- 本地模式：保留最近 10 个备份
- NAS 模式：通过 SSH 传输，清理 30 天前的备份
- 输出恢复命令

**恢复**：
```bash
# 从本地备份
tar -xzf ~/openclaw-backups/openclaw-backup-YYYYMMDD_HHMMSS.tar.gz -C $HOME

# 从 NAS 备份
scp -i ~/.ssh/id_nas openclaw-agent@ugreen-nas:/volume1/openclaw-backup/snapshots/latest.tar.gz /tmp/
tar -xzf /tmp/latest.tar.gz -C $HOME
```

---

## health-check.sh

全面检查 OpenClaw 的安装、配置、安全和运行状态。

```bash
bash scripts/health-check.sh
```

**检查项目**：
- 安装状态：OpenClaw、Docker、Tailscale
- 配置完整性：openclaw.json、SOUL.md、MEMORY.md
- 记忆状态：日志文件数量、最新记忆日期
- 安全检查：Gateway 绑定、DM 策略、沙箱模式、明文密钥、文件权限
- 电源管理：休眠、自动重启设置
- 运行状态：进程、端口监听、loopback 绑定验证
- NAS 连通性：Tailscale、SSH、SMB 挂载

**输出示例**：
```
【安装状态】
  ✓ OpenClaw 已安装: openclaw v2026.3.7
  ✓ Docker 可用且运行中
  ✓ Tailscale 可用且已连接

【安全状态】
  ✓ Gateway 未绑定到 0.0.0.0
  ✓ 沙箱模式: all
  ✓ 沙箱默认断网
  ✓ .env 文件权限正确 (600)

  结果: 18 通过  2 警告  0 失败
```

---

## rotate-keys.sh

API 密钥年龄检查和交互式轮换。

```bash
# 仅检查密钥年龄（不轮换）
bash scripts/rotate-keys.sh --check-only

# 交互式轮换
bash scripts/rotate-keys.sh
```

**功能**：
- 检查 .env 文件修改时间，提示密钥年龄
- 脱敏显示当前配置的密钥
- 交互式逐项更新（可跳过不需要更新的项）
- 自动验证新密钥格式（如 `sk-ant-` 前缀）
- 备份旧 .env 到 `~/.openclaw/key-history/`
- 重启 Gateway 使新密钥生效
- 提醒撤销旧密钥

**建议周期**：每 30 天执行一次

---

## verify-sandbox.sh

验证 OpenClaw 沙箱隔离和安全配置是否到位。

```bash
bash scripts/verify-sandbox.sh
```

**验证项目**：
1. Docker 沙箱环境（容器状态）
2. 配置文件隔离（沙箱模式、网络隔离）
3. 敏感文件保护（权限、明文密钥检查）
4. NAS 工作区与备份区隔离
5. Gateway 网络绑定（loopback 验证）
6. Tailscale 网络隔离
7. 通讯平台访问控制（DM 策略、白名单）

**对应测试用例**：TC-008-05, TC-008-07, TC-008-10

---

## test-008.sh

自动执行 008 章节的所有测试用例（TC-008-01 ~ TC-008-12）。

```bash
# 运行测试
bash scripts/test-008.sh

# 详细模式
bash scripts/test-008.sh --verbose
```

**自动化测试**（无需人工介入）：
- TC-008-01: 电源管理配置
- TC-008-02: Tailscale 组网
- TC-008-04: OpenClaw 服务启动与绑定
- TC-008-06: NAS SMB 挂载
- TC-008-07: NAS 备份区隔离
- TC-008-10: 密钥文件安全
- TC-008-11: 自动备份配置

**需手动验证**：
- TC-008-03: ACL 访问控制（需多设备）
- TC-008-05: 沙箱内文件访问（需通过 Telegram）
- TC-008-08: Tailscale Serve HTTPS（需其他设备）
- TC-008-09: 开机自启（需重启）
- TC-008-12: 多角色消息通讯（需多 Telegram 账号）

---

## 使用建议

| 场景 | 推荐操作 |
|------|----------|
| 首次安装 | `install.sh` |
| Mac Studio 服务器部署 | `setup-server.sh` → `test-008.sh` |
| 每日巡检 | `health-check.sh` |
| 修改配置/升级前 | `backup.sh` |
| 每月安全维护 | `rotate-keys.sh` → `verify-sandbox.sh` |
| 部署后验证 | `test-008.sh` |
| 疑似安全事件 | `verify-sandbox.sh` → `rotate-keys.sh` → `backup.sh --nas` |
