#!/bin/bash
# 008 章节测试用例自动执行脚本
# 用法: bash scripts/test-008.sh [--verbose]
#
# 对应测试: testcase/008-remote-sandbox.md (TC-008-01 ~ TC-008-12)
#
# 自动执行可自动化的测试用例，标注需手动验证的用例

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0
VERBOSE=false

[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; FAIL=$((FAIL + 1)); }
skip() { echo -e "  ${YELLOW}SKIP${NC}  $1 ${DIM}(需手动验证)${NC}"; SKIP=$((SKIP + 1)); }
tc()   { echo ""; echo -e "${CYAN}━━ $1 ━━${NC}"; }

OPENCLAW_DIR="$HOME/.openclaw"
NAS_WORKSPACE="$HOME/mounts/nas-workspace"
NAS_SSH_KEY="$HOME/.ssh/id_nas"
NAS_HOST="ugreen-nas"

echo "================================================="
echo "  008 章节自动化测试"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================="

# ── TC-008-01: Mac Studio 24/7 服务器配置 ──
tc "TC-008-01: Mac Studio 24/7 服务器配置"

if [[ "$(uname)" == "Darwin" ]]; then
    sleep_val=$(pmset -g 2>/dev/null | grep -w "sleep" | head -1 | awk '{print $NF}' || echo "?")
    disksleep_val=$(pmset -g 2>/dev/null | grep "disksleep" | awk '{print $NF}' || echo "?")
    autorestart_val=$(pmset -g 2>/dev/null | grep "autorestart" | awk '{print $NF}' || echo "?")
    womp_val=$(pmset -g 2>/dev/null | grep "womp" | awk '{print $NF}' || echo "?")

    [[ "$sleep_val" == "0" ]] && pass "sleep = 0" || fail "sleep = $sleep_val (应为 0)"
    [[ "$disksleep_val" == "0" ]] && pass "disksleep = 0" || fail "disksleep = $disksleep_val (应为 0)"
    [[ "$autorestart_val" == "1" ]] && pass "autorestart = 1" || fail "autorestart = $autorestart_val (应为 1)"
    [[ "$womp_val" == "1" ]] && pass "womp = 1" || fail "womp = $womp_val (应为 1)"
else
    skip "非 macOS 系统，跳过电源管理检查"
fi

# ── TC-008-02: Tailscale 组网验证 ──
tc "TC-008-02: Tailscale 组网验证"

if command -v tailscale &>/dev/null; then
    if tailscale status &>/dev/null 2>&1; then
        pass "Tailscale 已连接"

        device_count=$(tailscale status 2>/dev/null | grep -c "100\." || echo "0")
        if [[ "$device_count" -ge 2 ]]; then
            pass "tailnet 中有 ${device_count} 台设备"
        else
            fail "tailnet 中仅 ${device_count} 台设备（至少需要 Mac Studio + NAS）"
        fi

        if tailscale status 2>/dev/null | grep -q "$NAS_HOST"; then
            pass "NAS ($NAS_HOST) 在 tailnet 中"
        else
            fail "NAS ($NAS_HOST) 不在 tailnet 中"
        fi

        if ping -c 1 -W 3 "$NAS_HOST" &>/dev/null 2>&1; then
            pass "ping $NAS_HOST 成功"
        else
            fail "ping $NAS_HOST 失败"
        fi
    else
        fail "Tailscale 未连接"
    fi
else
    fail "Tailscale 未安装"
fi

# ── TC-008-03: Tailscale ACL 访问控制验证 ──
tc "TC-008-03: Tailscale ACL 访问控制验证"
skip "ACL 验证需从不同设备/角色测试，请手动执行"

# ── TC-008-04: OpenClaw 服务启动与绑定 ──
tc "TC-008-04: OpenClaw 服务启动与绑定"

if command -v openclaw &>/dev/null; then
    pass "OpenClaw 已安装"
else
    fail "OpenClaw 未安装"
fi

if launchctl list 2>/dev/null | grep -q "com.openclaw.gateway"; then
    pass "launchd 服务已注册"
else
    fail "launchd 服务未注册"
fi

if lsof -i :18789 &>/dev/null 2>&1; then
    if lsof -i :18789 2>/dev/null | grep -q "127.0.0.1"; then
        pass "Gateway 监听 127.0.0.1:18789（安全）"
    elif lsof -i :18789 2>/dev/null | grep -q "\*:18789"; then
        fail "Gateway 监听 0.0.0.0:18789（不安全）"
    else
        pass "Gateway 端口 18789 在监听"
    fi
else
    fail "端口 18789 未监听"
fi

# ── TC-008-05: Docker 沙箱隔离验证 ──
tc "TC-008-05: Docker 沙箱隔离验证"

if [[ -f "$OPENCLAW_DIR/openclaw.json" ]]; then
    if grep -q '"mode".*"all"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        pass "沙箱模式配置为 all"
    else
        fail "沙箱模式未配置为 all"
    fi

    if grep -q '"networkAccess".*false' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        pass "沙箱默认断网"
    else
        fail "沙箱网络未关闭"
    fi
else
    fail "openclaw.json 不存在"
fi

skip "沙箱内文件访问测试需通过 Telegram 向 Bot 发送命令验证"

# ── TC-008-06: NAS SMB 挂载验证 ──
tc "TC-008-06: NAS SMB 挂载验证"

if [[ -d "$NAS_WORKSPACE" ]]; then
    pass "挂载点目录存在: $NAS_WORKSPACE"

    if mount 2>/dev/null | grep -q "$NAS_WORKSPACE"; then
        mount_type=$(mount 2>/dev/null | grep "$NAS_WORKSPACE" | grep -o 'smbfs\|sshfs\|nfs' || echo "unknown")
        pass "已挂载 ($mount_type)"

        for subdir in projects archives uploads; do
            if [[ -d "$NAS_WORKSPACE/$subdir" ]]; then
                pass "子目录存在: $subdir/"
            else
                fail "子目录缺失: $subdir/"
            fi
        done

        # 读写测试
        test_file="$NAS_WORKSPACE/.test-$(date +%s)"
        if echo "test" > "$test_file" 2>/dev/null; then
            pass "工作区可写"
            rm -f "$test_file"
        else
            fail "工作区不可写"
        fi
    else
        fail "挂载点存在但未挂载"
    fi
else
    fail "挂载点目录不存在: $NAS_WORKSPACE"
fi

# ── TC-008-07: NAS 备份区隔离验证 ──
tc "TC-008-07: NAS 备份区隔离验证"

if [[ -f "$NAS_SSH_KEY" ]]; then
    # openclaw-agent 不应能访问 backup 目录
    if ssh -i "$NAS_SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes \
          "openclaw-agent@${NAS_HOST}" "test -d /volume1/openclaw-backup && echo accessible" 2>/dev/null | grep -q "accessible"; then
        fail "openclaw-agent 可访问备份区（应限制为 root）"
    else
        pass "openclaw-agent 无法访问备份区（隔离正确）"
    fi
else
    skip "NAS SSH 密钥不存在，无法验证"
fi

# ── TC-008-08: Tailscale Serve HTTPS 访问 ──
tc "TC-008-08: Tailscale Serve HTTPS 访问"
skip "需从 tailnet 内其他设备访问 HTTPS URL 验证"

# ── TC-008-09: 开机自启全链路验证 ──
tc "TC-008-09: 开机自启全链路验证"
skip "需重启 Mac Studio 后验证（破坏性测试）"

# ── TC-008-10: 密钥文件安全验证 ──
tc "TC-008-10: 密钥文件安全验证"

if [[ -f "$OPENCLAW_DIR/.env" ]]; then
    env_perms=$(stat -f %Lp "$OPENCLAW_DIR/.env" 2>/dev/null || stat -c %a "$OPENCLAW_DIR/.env" 2>/dev/null || echo "?")
    [[ "$env_perms" == "600" ]] && pass ".env 权限 600" || fail ".env 权限 $env_perms (应为 600)"
else
    fail ".env 文件不存在"
fi

if [[ -f "$OPENCLAW_DIR/openclaw.json" ]]; then
    if grep -qE '(sk-ant-|sk-or-)[a-zA-Z0-9]{10,}' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
        fail "openclaw.json 含明文 API Key"
    else
        pass "openclaw.json 无明文密钥"
    fi
fi

# ── TC-008-11: 自动备份验证 ──
tc "TC-008-11: 自动备份验证"

backup_script="$HOME/.openclaw/scripts/backup.sh"
if [[ -f "$backup_script" ]]; then
    pass "备份脚本存在: $backup_script"
    if [[ -x "$backup_script" ]]; then
        pass "备份脚本可执行"
    else
        fail "备份脚本不可执行（chmod 700 $backup_script）"
    fi
else
    # 检查项目中的脚本
    local_script="$(cd "$(dirname "$0")" && pwd)/backup.sh"
    if [[ -f "$local_script" ]]; then
        pass "备份脚本在项目中: $local_script（未部署到 ~/.openclaw/scripts/）"
    else
        fail "备份脚本不存在"
    fi
fi

if crontab -l 2>/dev/null | grep -q "backup"; then
    pass "备份 cron 已配置"
else
    fail "备份 cron 未配置"
fi

# ── TC-008-12: 多角色消息通讯 ──
tc "TC-008-12: 多角色消息通讯"
skip "需通过 Telegram 从不同账号发送消息验证"

# ── 汇总 ──
echo ""
echo "================================================="
echo "  008 测试结果汇总"
echo ""
echo -e "  ${GREEN}${PASS} 通过${NC}  ${RED}${FAIL} 失败${NC}  ${YELLOW}${SKIP} 需手动${NC}"
TOTAL=$((PASS + FAIL + SKIP))
echo "  共 ${TOTAL} 项检查"
echo "================================================="

if [[ "$FAIL" -gt 0 ]]; then
    echo ""
    echo "存在失败项。参考 guide/008-remote-sandbox.md 和 testcase/008-remote-sandbox.md 修复。"
    exit 1
fi

if [[ "$SKIP" -gt 0 ]]; then
    echo ""
    echo "以下测试需要手动验证："
    echo "  - TC-008-03: 从不同设备测试 ACL"
    echo "  - TC-008-05: 通过 Telegram 测试沙箱内文件访问"
    echo "  - TC-008-08: 从 tailnet 内设备访问 HTTPS"
    echo "  - TC-008-09: 重启后验证自动恢复"
    echo "  - TC-008-12: 多角色 Telegram 消息测试"
fi
