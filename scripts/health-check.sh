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

if launchctl list 2>/dev/null | grep -q "com.openclaw.gateway"; then
    pass "OpenClaw launchd 服务已注册"
else
    warn "OpenClaw launchd 服务未注册（可手动运行）"
fi

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

# 7. NAS 连通性检查（仅在配置了 NAS 时执行）
NAS_HOST="ugreen-nas"
NAS_MOUNT="$HOME/mounts/nas-archive"
NAS_SSH_KEY="$HOME/.ssh/id_nas"

if [[ -f "$NAS_SSH_KEY" ]] || [[ -d "$NAS_MOUNT" ]]; then
    echo ""
    echo "【NAS 连通性（Mac Studio 中心节点模式）】"

    # Tailscale 连通性
    if command -v tailscale &>/dev/null; then
        if tailscale status 2>/dev/null | grep -q "$NAS_HOST"; then
            pass "NAS 在 tailnet 中可见：$NAS_HOST"
        else
            warn "NAS ($NAS_HOST) 不在当前 tailnet 中，检查 Tailscale 连接"
        fi
    fi

    # SSH 密钥
    if [[ -f "$NAS_SSH_KEY" ]]; then
        key_perms=$(stat -f %Lp "$NAS_SSH_KEY" 2>/dev/null || stat -c %a "$NAS_SSH_KEY" 2>/dev/null || echo "unknown")
        if [[ "$key_perms" == "600" ]]; then
            pass "NAS SSH 密钥权限正确 (600): $NAS_SSH_KEY"
        else
            warn "NAS SSH 密钥权限为 $key_perms，建议设为 600"
        fi
    else
        warn "未找到 NAS SSH 密钥：$NAS_SSH_KEY（如使用中心节点模式请配置）"
    fi

    # SSHFS 挂载状态
    if [[ -d "$NAS_MOUNT" ]]; then
        if mount 2>/dev/null | grep -q "$NAS_MOUNT"; then
            pass "NAS 工作区已挂载：$NAS_MOUNT"
        else
            warn "NAS 工作区目录存在但未挂载：$NAS_MOUNT"
        fi
    else
        warn "NAS 挂载目录不存在：$NAS_MOUNT（如使用中心节点模式请创建）"
    fi

    # NAS SSH 连通性测试（快速超时）
    if [[ -f "$NAS_SSH_KEY" ]] && command -v ssh &>/dev/null; then
        if ssh -i "$NAS_SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes \
              -o StrictHostKeyChecking=accept-new \
              "openclaw-agent@$NAS_HOST" "echo ok" &>/dev/null 2>&1; then
            pass "Mac Studio → NAS SSH 连接正常"
        else
            warn "Mac Studio → NAS SSH 连接失败（NAS 可能离线或 Tailscale 未连接）"
        fi
    fi
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
