# 测试用例：001 - macOS 安装

> 对应指南 [001 - macOS 安装指南](../guide/001-macos-installation.md)

## TC-001-01：Homebrew 安装

**操作步骤**：
1. 打开终端
2. 执行 `brew tap openclaw/tap`
3. 执行 `brew install openclaw`
4. 执行 `openclaw --version`

**测试目标**：验证 Homebrew 安装路径正确完成

**预期结果**：
- `brew tap` 成功，无报错
- `brew install` 下载并安装 openclaw 包
- `openclaw --version` 输出版本号（如 `openclaw v2026.3.x`）

---

## TC-001-02：Apple Silicon 环境变量

**前置条件**：M 系列芯片 Mac

**操作步骤**：
1. 执行 `echo 'export OPENCLAW_ARCH=arm64' >> ~/.zshrc`
2. 执行 `source ~/.zshrc`
3. 执行 `echo $OPENCLAW_ARCH`

**测试目标**：验证 ARM64 环境变量正确设置

**预期结果**：
- `echo $OPENCLAW_ARCH` 输出 `arm64`

---

## TC-001-03：openclaw doctor 诊断

**前置条件**：OpenClaw 已安装

**操作步骤**：
1. 执行 `openclaw doctor`

**测试目标**：验证诊断工具可正常运行

**预期结果**：
- 输出各项检查结果
- 无 ERROR 级别的问题（WARNING 可接受）
- 如有可自动修复的问题，提示修复建议

---

## TC-001-04：npm 安装

**操作步骤**：
1. 确认 Node.js 版本 ≥ 22：`node --version`
2. 执行 `npm install -g openclaw`
3. 执行 `openclaw --version`

**测试目标**：验证 npm 安装路径正确完成

**预期结果**：
- Node.js 版本 ≥ v22.0.0
- npm 安装无 EACCES 错误
- `openclaw --version` 输出版本号

---

## TC-001-05：Docker 安装

**前置条件**：Docker Desktop 已安装，内存分配 ≥ 4 GB

**操作步骤**：
1. 执行 `docker pull alpine/openclaw:latest`
2. 执行容器启动命令（见指南）
3. 执行 `docker ps | grep openclaw`
4. 等待 30 秒后执行 `docker logs openclaw`

**测试目标**：验证 Docker 容器正常启动

**预期结果**：
- 镜像拉取成功
- `docker ps` 显示 openclaw 容器状态为 `Up`
- 日志中无 `ERROR` 或 `FATAL`
- 端口 18789 正常监听

---

## TC-001-06：升级验证

**前置条件**：OpenClaw 已安装旧版本

**操作步骤**：
1. 记录当前版本：`openclaw --version`
2. 执行 `openclaw update`（或 `brew upgrade openclaw`）
3. 执行 `openclaw --version`
4. 执行 `openclaw doctor`

**测试目标**：验证升级流程无破坏性

**预期结果**：
- 版本号已更新
- `openclaw doctor` 通过
- `~/.openclaw/` 配置文件保留
