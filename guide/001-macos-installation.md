# 001 - macOS 安装指南

> 本章介绍在 macOS 上安装 OpenClaw 的三种方式：Homebrew、npm 和 Docker。

## 前置要求

| 项目 | 最低要求 |
|------|----------|
| macOS 版本 | 12 (Monterey) 或更高 |
| 芯片 | Intel 或 Apple Silicon (M1/M2/M3/M4) |
| 磁盘空间 | ≥ 2 GB（Docker 模式需 ≥ 4 GB） |
| 内存 | ≥ 8 GB（推荐 16 GB） |

## 方式一：Homebrew 安装（推荐）

这是最简单的本地安装方式。

### 1. 安装 Homebrew（如未安装）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. 安装 OpenClaw

```bash
brew tap openclaw/tap
brew install openclaw
```

### 3. Apple Silicon 额外配置

如果你使用的是 M 系列芯片的 Mac：

```bash
echo 'export OPENCLAW_ARCH=arm64' >> ~/.zshrc
source ~/.zshrc
```

### 4. 验证安装

```bash
openclaw --version
# 预期输出：openclaw v2026.3.x
```

### 5. 运行诊断

```bash
openclaw doctor
```

`openclaw doctor` 会自动检测并修复常见配置问题。**安装后、每次升级后、每次修改配置后都建议运行此命令。**

## 方式二：npm 安装

如果你已经有 Node.js 环境，这是最快的路径。

### 1. 安装 Node.js（如未安装）

```bash
# 推荐使用 nvm 管理 Node.js 版本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.zshrc
nvm install 22
nvm use 22
```

> **注意**：OpenClaw 要求 Node.js 22 或更高版本。

### 2. 全局安装 OpenClaw

```bash
npm install -g openclaw
```

> **注意**：不要使用 `sudo npm install -g`。如果遇到 EACCES 权限错误，请修复 npm 目录权限：
> ```bash
> mkdir -p ~/.npm-global
> npm config set prefix '~/.npm-global'
> echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
> source ~/.zshrc
> npm install -g openclaw
> ```

### 3. 验证安装

```bash
openclaw --version
openclaw doctor
```

## 方式三：Docker 安装

Docker 模式提供最佳的安全隔离，适合希望严格控制代理权限的用户。

### 1. 安装 Docker Desktop

从 [Docker 官网](https://www.docker.com/products/docker-desktop/) 下载并安装 Docker Desktop for Mac。

安装后进入 **Settings → Resources**，将内存分配调整到 **≥ 4 GB**。

### 2. 使用官方脚本安装

```bash
# 克隆仓库
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# 运行 Docker 安装脚本
./docker-setup.sh
```

脚本会自动创建两个关键目录（作为 Docker Volume 挂载）：

| 目录 | 用途 |
|------|------|
| `~/.openclaw/` | 配置文件、记忆文件、API 密钥等 |
| `~/openclaw/workspace/` | 代理可直接访问的工作目录 |

### 3. 使用预构建镜像（无需克隆仓库）

```bash
# 拉取官方镜像
docker pull alpine/openclaw:latest

# 启动容器
docker run -d \
  --name openclaw \
  -v ~/.openclaw:/root/.openclaw \
  -v ~/openclaw/workspace:/workspace \
  -p 18789:18789 \
  alpine/openclaw:latest
```

> **官方 Docker 镜像**：[hub.docker.com/r/alpine/openclaw](https://hub.docker.com/r/alpine/openclaw)
> **Docker 文档**：[docs.openclaw.ai/install/docker](https://docs.openclaw.ai/install/docker)

### 4. macOS Docker 注意事项

- macOS 上 Docker 通过 Linux VM 层运行，相比原生安装会有一些性能开销
- 连接宿主机服务（如 Ollama）时，使用 `host.docker.internal` 而非 `localhost`
- 个人使用场景下，原生 npm/Homebrew 安装通常是更好的选择
- Docker 在 VPS 部署或需要严格沙箱隔离时更有优势

## 升级

```bash
# Homebrew
brew upgrade openclaw

# npm
npm update -g openclaw

# Docker
docker pull alpine/openclaw:latest
# 然后重建容器

# 通用方式
openclaw update
```

升级后务必运行：

```bash
openclaw doctor
```

## 卸载

```bash
# Homebrew
brew uninstall openclaw
brew untap openclaw/tap

# npm
npm uninstall -g openclaw

# Docker
docker stop openclaw && docker rm openclaw
docker rmi alpine/openclaw:latest
```

配置文件目录 `~/.openclaw/` 不会被自动删除，如需清理请手动删除。

## 下一步

安装完成后，进入 [002 - 基本配置与运行](002-basic-configuration.md) 进行初始配置。

## 参考来源

- [OpenClaw 官方文档 - Docker 安装](https://docs.openclaw.ai/install/docker)
- [Homebrew 官方文档](https://brew.sh/)
- [OpenClaw GitHub 仓库](https://github.com/openclaw/openclaw)
- [Cult of Mac - 如何在 Mac 上设置 OpenClaw](https://www.cultofmac.com/how-to/set-up-and-run-openclaw-on-mac)
