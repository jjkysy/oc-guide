# scripts/ - 便捷脚本

> OpenClaw 安装、维护和诊断用的自动化脚本。

## 脚本列表

| 脚本 | 用途 | 用法 |
|------|------|------|
| `install.sh` | macOS 快速安装 | `bash scripts/install.sh [homebrew\|npm\|docker]` |
| `backup.sh` | 配置和记忆备份 | `bash scripts/backup.sh [备份目录]` |
| `health-check.sh` | 运行状态健康检查 | `bash scripts/health-check.sh` |

---

## install.sh

一键安装 OpenClaw，支持三种安装方式。

```bash
# 交互式选择安装方式
bash scripts/install.sh

# 直接指定安装方式
bash scripts/install.sh homebrew    # 推荐
bash scripts/install.sh npm
bash scripts/install.sh docker
```

**功能**：
- 自动检测 macOS 版本和芯片架构
- Apple Silicon 自动设置 `OPENCLAW_ARCH=arm64`
- 安装完成后自动运行 `openclaw doctor` 诊断
- npm 安装自动处理权限问题（避免 sudo）

---

## backup.sh

备份 `~/.openclaw/` 目录中的配置、记忆和代理文件。

```bash
# 备份到默认位置 ~/openclaw-backups/
bash scripts/backup.sh

# 指定备份目录
bash scripts/backup.sh /path/to/backups
```

**功能**：
- 自动排除日志和临时会话文件（减小备份体积）
- 自动清理旧备份（保留最近 10 个）
- 输出备份文件大小和恢复命令

**恢复**：
```bash
tar -xzf ~/openclaw-backups/openclaw-backup-YYYYMMDD_HHMMSS.tar.gz -C $HOME
```

---

## health-check.sh

全面检查 OpenClaw 的安装、配置和运行状态。

```bash
bash scripts/health-check.sh
```

**检查项目**：
- 安装状态：OpenClaw、Docker、Tailscale
- 配置完整性：openclaw.json、SOUL.md、MEMORY.md
- 记忆状态：日志文件数量、最新记忆日期
- 安全检查：Gateway 绑定、DM 策略、文件权限
- 运行状态：进程、端口监听

**输出示例**：
```
【安装状态】
  ✓ OpenClaw 已安装: openclaw v2026.3.7
  ✓ Docker 可用
  ✓ Tailscale 可用

【安全状态】
  ✓ Gateway 未绑定到 0.0.0.0
  ✗ DM 策略为 open（任何人可对话）

  结果: 8 通过  2 警告  1 失败
```

---

## 使用建议

| 场景 | 推荐操作 |
|------|----------|
| 首次安装 | `bash scripts/install.sh` |
| 每日巡检 | `bash scripts/health-check.sh` |
| 修改配置前 | `bash scripts/backup.sh` |
| 升级前 | `bash scripts/backup.sh` → 升级 → `bash scripts/health-check.sh` |
| 定期维护 | 每周运行一次 backup + health-check |
