#!/bin/bash
# OpenClaw macOS 快速安装脚本
# 用法: bash scripts/install.sh [homebrew|npm|docker]
#
# 参考来源:
# - https://docs.openclaw.ai/start/getting-started
# - https://github.com/openclaw/openclaw

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "此脚本仅支持 macOS"
    fi
    info "检测到 macOS $(sw_vers -productVersion)"
}

check_arch() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        info "检测到 Apple Silicon (${arch})"
        export OPENCLAW_ARCH=arm64
        if ! grep -q 'OPENCLAW_ARCH' ~/.zshrc 2>/dev/null; then
            echo 'export OPENCLAW_ARCH=arm64' >> ~/.zshrc
            info "已添加 OPENCLAW_ARCH=arm64 到 ~/.zshrc"
        fi
    else
        info "检测到 Intel (${arch})"
    fi
}

install_homebrew() {
    info "=== Homebrew 安装 ==="

    if ! command -v brew &>/dev/null; then
        warn "未检测到 Homebrew，正在安装..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    info "添加 OpenClaw tap..."
    brew tap openclaw/tap

    info "安装 OpenClaw..."
    brew install openclaw

    info "验证安装..."
    openclaw --version

    info "运行诊断..."
    openclaw doctor

    info "Homebrew 安装完成！"
}

install_npm() {
    info "=== npm 安装 ==="

    if ! command -v node &>/dev/null; then
        warn "未检测到 Node.js"
        if command -v nvm &>/dev/null; then
            info "通过 nvm 安装 Node.js 22..."
            nvm install 22
            nvm use 22
        else
            error "请先安装 Node.js 22+: https://nodejs.org/"
        fi
    fi

    local node_version
    node_version=$(node --version | sed 's/v//' | cut -d. -f1)
    if [[ "$node_version" -lt 22 ]]; then
        error "Node.js 版本需 >= 22，当前版本: $(node --version)"
    fi
    info "Node.js 版本: $(node --version)"

    # 避免权限问题
    if [[ ! -d ~/.npm-global ]]; then
        mkdir -p ~/.npm-global
        npm config set prefix '~/.npm-global'
        if ! grep -q '.npm-global/bin' ~/.zshrc 2>/dev/null; then
            echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
            export PATH=~/.npm-global/bin:$PATH
        fi
    fi

    info "安装 OpenClaw..."
    npm install -g openclaw

    info "验证安装..."
    openclaw --version

    info "运行诊断..."
    openclaw doctor

    info "npm 安装完成！"
}

install_docker() {
    info "=== Docker 安装 ==="

    if ! command -v docker &>/dev/null; then
        error "请先安装 Docker Desktop: https://www.docker.com/products/docker-desktop/"
    fi

    if ! docker info &>/dev/null; then
        error "Docker 未运行，请启动 Docker Desktop"
    fi

    info "创建目录..."
    mkdir -p ~/.openclaw
    mkdir -p ~/openclaw/workspace

    info "拉取 OpenClaw 镜像..."
    docker pull alpine/openclaw:latest

    info "启动容器..."
    docker run -d \
        --name openclaw \
        --restart unless-stopped \
        -v ~/.openclaw:/root/.openclaw \
        -v ~/openclaw/workspace:/workspace \
        -p 127.0.0.1:18789:18789 \
        alpine/openclaw:latest

    info "等待启动..."
    sleep 5

    if docker ps | grep -q openclaw; then
        info "Docker 安装完成！容器已启动。"
        info "查看日志: docker logs openclaw"
    else
        error "容器启动失败，请检查: docker logs openclaw"
    fi
}

# 主逻辑
main() {
    local method="${1:-}"

    echo "================================================="
    echo "  OpenClaw macOS 快速安装脚本"
    echo "================================================="
    echo ""

    check_macos
    check_arch

    if [[ -z "$method" ]]; then
        echo ""
        echo "请选择安装方式:"
        echo "  1) homebrew  (推荐)"
        echo "  2) npm"
        echo "  3) docker"
        echo ""
        read -rp "请输入选项 [1/2/3]: " choice
        case "$choice" in
            1|homebrew) method="homebrew" ;;
            2|npm)      method="npm" ;;
            3|docker)   method="docker" ;;
            *) error "无效选项: $choice" ;;
        esac
    fi

    case "$method" in
        homebrew) install_homebrew ;;
        npm)      install_npm ;;
        docker)   install_docker ;;
        *) error "未知安装方式: $method。支持: homebrew, npm, docker" ;;
    esac

    echo ""
    info "下一步: 编辑 ~/.openclaw/openclaw.json 配置你的 API Key 和通讯平台"
    info "参考指南: guide/002-basic-configuration.md"
}

main "$@"
