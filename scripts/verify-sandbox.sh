#!/bin/bash
# OpenClaw 沙箱隔离验证脚本
# 用法: bash scripts/verify-sandbox.sh
#
# 对应测试: TC-008-05, TC-008-07, TC-008-10
#
# 验证:
# - Docker 沙箱是否正确隔离敏感文件
# - NAS 备份区是否与工作区隔离
# - OpenClaw 配置是否在沙箱外
# - 网络隔离状态

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; WARN=$((WARN + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }

OPENCLAW_DIR="$HOME/.openclaw"
NAS_WORKSPACE="$HOME/mounts/nas-workspace"
NAS_HOST="ugreen-nas"
NAS_SSH_KEY="$HOME/.ssh/id_nas"

echo "================================================="
echo "  OpenClaw 沙箱隔离验证"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================="

# ── 1. Docker 环境检查 ──
echo ""
echo -e "${CYAN}【1. Docker 沙箱环境】${NC}"

if ! command -v docker &>/dev/null; then
    fail "Docker 未安装，沙箱功能不可用"
elif ! docker info &>/dev/null 2>&1; then
    fail "Docker 未运行"
else
    pass "Docker 运行中"

    # 检查是否有 OpenClaw 相关容器
    if docker ps -a 2>/dev/null | grep -qi "openclaw\|sandbox"; then
        pass "检测到 OpenClaw/sandbox 容器"
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | grep -i "openclaw\|sandbox" | while read -r line; do
            echo "    $line"
        done
    else
        warn "未检测到 OpenClaw 容器（可能使用即时创建模式）"
    fi
fi

# ── 2. 配置文件隔离 ──
echo ""
echo -e "${CYAN}【2. 配置文件隔离验证】${NC}"

# 检查 openclaw.json 中的沙箱配置
if [[ -f "$OPENCLAW_DIR/openclaw.json" ]]; then
    if grep -q '"mode".*"all"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        pass "沙箱模式: all（所有操作在 Docker 中执行）"
    elif grep -q '"mode".*"non-main"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        warn "沙箱模式: non-main（主线程在宿主机，风险较高）"
    elif grep -q '"mode".*"none"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        fail "沙箱模式: none（无隔离）"
    else
        warn "未检测到明确的沙箱模式配置"
    fi

    # 网络隔离
    if grep -q '"networkAccess".*false' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        pass "沙箱默认断网 (networkAccess: false)"
    elif grep -q '"networkAccess".*true' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        warn "沙箱网络已开启 — 被入侵时可外传数据"
    fi
else
    fail "openclaw.json 不存在"
fi

# 检查敏感文件权限
echo ""
echo -e "${CYAN}【3. 敏感文件保护】${NC}"

sensitive_files=(
    "$OPENCLAW_DIR/.env"
    "$OPENCLAW_DIR/credentials"
    "$HOME/.ssh/id_nas"
    "$HOME/.ssh/id_nas.pub"
)

for f in "${sensitive_files[@]}"; do
    if [[ -e "$f" ]]; then
        if [[ -d "$f" ]]; then
            local_perms=$(stat -f %Lp "$f" 2>/dev/null || stat -c %a "$f" 2>/dev/null || echo "unknown")
            if [[ "$local_perms" -le 700 ]]; then
                pass "$(basename "$f")/ 权限: $local_perms"
            else
                fail "$(basename "$f")/ 权限过大: $local_perms，建议 700 或更低"
            fi
        else
            local_perms=$(stat -f %Lp "$f" 2>/dev/null || stat -c %a "$f" 2>/dev/null || echo "unknown")
            if [[ "$local_perms" -le 600 ]]; then
                pass "$(basename "$f") 权限: $local_perms"
            else
                fail "$(basename "$f") 权限过大: $local_perms，建议 600"
            fi
        fi
    fi
done

# 检查 openclaw.json 中是否有明文密钥
if [[ -f "$OPENCLAW_DIR/openclaw.json" ]]; then
    if grep -qE '(sk-ant-|sk-or-)[a-zA-Z0-9]{10,}' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        fail "openclaw.json 中包含明文 API Key！应使用 \${VAR} 引用"
    else
        pass "openclaw.json 中无明文 API Key"
    fi

    if grep -qE '"botToken"\s*:\s*"[0-9]+:[a-zA-Z]' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        fail "openclaw.json 中包含明文 Bot Token！应使用 \${VAR} 引用"
    else
        pass "openclaw.json 中无明文 Bot Token"
    fi
fi

# ── 4. NAS 隔离验证 ──
echo ""
echo -e "${CYAN}【4. NAS 工作区与备份区隔离】${NC}"

# 工作区挂载
if [[ -d "$NAS_WORKSPACE" ]]; then
    if mount 2>/dev/null | grep -q "$NAS_WORKSPACE"; then
        mount_type=$(mount 2>/dev/null | grep "$NAS_WORKSPACE" | grep -o 'smbfs\|sshfs\|nfs' || echo "unknown")
        pass "工作区已挂载: $NAS_WORKSPACE ($mount_type)"

        # 检查工作区子目录
        for subdir in projects archives uploads; do
            if [[ -d "$NAS_WORKSPACE/$subdir" ]]; then
                pass "  子目录存在: $subdir/"
            else
                warn "  子目录缺失: $subdir/"
            fi
        done
    else
        warn "工作区目录存在但未挂载"
    fi
else
    warn "工作区挂载点不存在: $NAS_WORKSPACE"
fi

# 备份区隔离：从 Mac Studio 不应能直接 mount 备份区
# 这里只能通过 SSH 验证备份区存在但不通过 SMB 暴露
if [[ -f "$NAS_SSH_KEY" ]]; then
    echo ""
    echo "  验证 NAS 备份区隔离（通过 SSH 检查）..."

    # 检查备份区是否存在
    if ssh -i "$NAS_SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes \
          "openclaw-agent@${NAS_HOST}" "test -d /volume1/openclaw-backup" &>/dev/null 2>&1; then
        # openclaw-agent 不应该能访问 backup 目录
        fail "openclaw-agent 可以访问备份区 /volume1/openclaw-backup（应限制权限为 root）"
    else
        pass "openclaw-agent 无法访问备份区（权限隔离正确）"
    fi
fi

# ── 5. Gateway 绑定验证 ──
echo ""
echo -e "${CYAN}【5. Gateway 网络绑定】${NC}"

if lsof -i :18789 &>/dev/null 2>&1; then
    if lsof -i :18789 2>/dev/null | grep -q "127.0.0.1"; then
        pass "Gateway 仅监听 127.0.0.1:18789"
    elif lsof -i :18789 2>/dev/null | grep -q "\*:18789"; then
        fail "Gateway 监听在 0.0.0.0:18789（任何网络可达，极不安全）"
    else
        warn "Gateway 端口 18789 在监听，无法确定绑定地址"
    fi
else
    warn "Gateway 端口 18789 未监听（服务可能未运行）"
fi

# ── 6. Tailscale ACL 验证 ──
echo ""
echo -e "${CYAN}【6. Tailscale 网络隔离】${NC}"

if command -v tailscale &>/dev/null && tailscale status &>/dev/null 2>&1; then
    pass "Tailscale 已连接"

    # 检查设备数
    device_count=$(tailscale status 2>/dev/null | grep -c "100\." || echo "0")
    echo "  当前 tailnet 设备数: $device_count"

    # 检查 NAS 是否可见
    if tailscale status 2>/dev/null | grep -q "$NAS_HOST"; then
        pass "NAS ($NAS_HOST) 在 tailnet 中可见"
    fi
else
    warn "Tailscale 未连接，无法验证网络隔离"
fi

# ── 7. 通讯平台安全 ──
echo ""
echo -e "${CYAN}【7. 通讯平台访问控制】${NC}"

if [[ -f "$OPENCLAW_DIR/openclaw.json" ]]; then
    # 检查 DM 策略
    if grep -q '"dmPolicy".*"allowlist"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        pass "DM 策略: allowlist（仅白名单用户可对话）"
    elif grep -q '"dmPolicy".*"pairing"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        warn "DM 策略: pairing（首次需配对，但后续开放）"
    elif grep -q '"dmPolicy".*"open"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        fail "DM 策略: open（任何人可对话，极不安全）"
    fi

    # 检查 allowFrom
    if grep -q '"allowFrom"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        pass "已配置 allowFrom 白名单"
    else
        warn "未检测到 allowFrom 白名单配置"
    fi
fi

# ── 汇总 ──
echo ""
echo "================================================="
echo -e "  沙箱隔离验证结果:"
echo -e "  ${GREEN}${PASS} 通过${NC}  ${YELLOW}${WARN} 警告${NC}  ${RED}${FAIL} 失败${NC}"
echo "================================================="

if [[ "$FAIL" -gt 0 ]]; then
    echo ""
    echo "存在安全隔离失败项，请参考 guide/008-remote-sandbox.md 修复。"
    exit 1
elif [[ "$WARN" -gt 2 ]]; then
    echo ""
    echo "部分项目需要关注，建议逐项检查。"
    exit 0
else
    echo ""
    echo "沙箱隔离状态良好。"
    exit 0
fi
