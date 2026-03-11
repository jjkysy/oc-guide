#!/bin/bash
# OpenClaw 健康检查脚本
# 用法: bash scripts/health-check.sh
#
# 检查 OpenClaw 运行状态、配置完整性和安全设置

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; WARN=$((WARN + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }

echo "================================================="
echo "  OpenClaw 健康检查"
echo "================================================="
echo ""

# 1. 安装检查
echo "【安装状态】"
if command -v openclaw &>/dev/null; then
    pass "OpenClaw 已安装: $(openclaw --version 2>/dev/null || echo '版本未知')"
else
    fail "OpenClaw 未安装"
fi

if command -v docker &>/dev/null; then
    pass "Docker 可用"
else
    warn "Docker 未安装（沙箱功能不可用）"
fi

if command -v tailscale &>/dev/null; then
    pass "Tailscale 可用"
else
    warn "Tailscale 未安装（远程访问不可用）"
fi

# 2. 配置检查
echo ""
echo "【配置状态】"
OPENCLAW_DIR="$HOME/.openclaw"

if [[ -d "$OPENCLAW_DIR" ]]; then
    pass "配置目录存在: $OPENCLAW_DIR"
else
    fail "配置目录不存在: $OPENCLAW_DIR"
fi

if [[ -f "$OPENCLAW_DIR/openclaw.json" ]]; then
    pass "配置文件存在: openclaw.json"

    # 检查配置文件大小
    local_size=$(wc -c < "$OPENCLAW_DIR/openclaw.json" 2>/dev/null || echo "0")
    if [[ "$local_size" -lt 10 ]]; then
        warn "配置文件可能为空或过小"
    fi
else
    fail "配置文件不存在"
fi

# 3. 代理文件检查
echo ""
echo "【代理状态】"

if [[ -f "$OPENCLAW_DIR/agents/default/SOUL.md" ]]; then
    pass "SOUL.md 存在"
    soul_size=$(wc -l < "$OPENCLAW_DIR/agents/default/SOUL.md" 2>/dev/null || echo "0")
    if [[ "$soul_size" -lt 5 ]]; then
        warn "SOUL.md 内容较少（仅 ${soul_size} 行），建议丰富人格定义"
    fi
else
    warn "SOUL.md 不存在，代理将使用默认人格"
fi

if [[ -f "$OPENCLAW_DIR/agents/default/MEMORY.md" ]]; then
    pass "MEMORY.md 存在"
else
    warn "MEMORY.md 不存在，长期记忆为空"
fi

# 4. 记忆文件检查
echo ""
echo "【记忆状态】"

if [[ -d "$OPENCLAW_DIR/memory" ]]; then
    memory_count=$(ls -1 "$OPENCLAW_DIR/memory/"*.md 2>/dev/null | wc -l || echo "0")
    pass "记忆目录存在，${memory_count} 个日志文件"

    # 检查最近的记忆文件
    latest=$(ls -1t "$OPENCLAW_DIR/memory/"*.md 2>/dev/null | head -1 || echo "")
    if [[ -n "$latest" ]]; then
        pass "最新记忆: $(basename "$latest")"
    fi
else
    warn "记忆目录不存在"
fi

# 5. 安全检查
echo ""
echo "【安全状态】"

# 检查 Gateway 绑定
if [[ -f "$OPENCLAW_DIR/openclaw.json" ]]; then
    if grep -q '"0.0.0.0"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        fail "Gateway 绑定到 0.0.0.0（暴露到所有网络接口）"
    else
        pass "Gateway 未绑定到 0.0.0.0"
    fi

    if grep -q '"dmPolicy".*"open"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        fail "DM 策略为 open（任何人可对话）"
    else
        pass "DM 策略非 open"
    fi
fi

# 检查 .env 文件权限
if [[ -f "$OPENCLAW_DIR/.env" ]]; then
    env_perms=$(stat -f %Lp "$OPENCLAW_DIR/.env" 2>/dev/null || stat -c %a "$OPENCLAW_DIR/.env" 2>/dev/null || echo "unknown")
    if [[ "$env_perms" == "600" ]]; then
        pass ".env 文件权限正确 (600)"
    else
        warn ".env 文件权限为 $env_perms，建议设为 600"
    fi
fi

# 6. 进程检查
echo ""
echo "【运行状态】"

if pgrep -f "openclaw" &>/dev/null; then
    pass "OpenClaw 进程运行中"
elif docker ps 2>/dev/null | grep -q openclaw; then
    pass "OpenClaw Docker 容器运行中"
else
    warn "OpenClaw 未运行"
fi

# 端口检查
if lsof -i :18789 &>/dev/null 2>&1; then
    pass "端口 18789 已监听"
else
    warn "端口 18789 未监听"
fi

# 汇总
echo ""
echo "================================================="
echo -e "  结果: ${GREEN}${PASS} 通过${NC}  ${YELLOW}${WARN} 警告${NC}  ${RED}${FAIL} 失败${NC}"
echo "================================================="

if [[ "$FAIL" -gt 0 ]]; then
    echo ""
    echo "建议运行 'openclaw doctor' 获取详细诊断。"
    exit 1
fi
