#!/bin/bash
# Mac Studio 24/7 服务器快速配置脚本
# 用法: bash scripts/setup-server.sh
#
# 对应指南: guide/008-remote-sandbox.md
# 对应测试: TC-008-01, TC-008-04, TC-008-09
#
# 功能:
# - 配置电源管理（禁用休眠、掉电自动重启）
# - 检查 Tailscale 安装和连接
# - 创建 NAS 挂载点和 SSH 密钥
# - 配置 OpenClaw launchd 服务
# - 配置 NAS SMB 自动挂载

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo ""; echo -e "${CYAN}═══ $1 ═══${NC}"; }

# ── 前置检查 ──
check_prerequisites() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "此脚本仅支持 macOS"
    fi
    info "macOS $(sw_vers -productVersion) ($(uname -m))"

    if [[ "$(uname -m)" != "arm64" ]]; then
        warn "检测到 Intel Mac。Mac Studio 通常为 Apple Silicon，请确认。"
    fi
}

# ── 1. 电源管理 ──
setup_power() {
    section "1. 电源管理配置"

    echo "将配置以下设置（需要 sudo）："
    echo "  - sleep 0       : 禁用系统休眠"
    echo "  - disksleep 0   : 禁用磁盘休眠"
    echo "  - autorestart 1 : 掉电后自动重启"
    echo "  - womp 1        : 允许网络唤醒"
    echo ""
    read -rp "是否继续？[y/N] " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        warn "跳过电源管理配置"
        return
    fi

    sudo pmset -a sleep 0
    sudo pmset -a disksleep 0
    sudo pmset -a autorestart 1
    sudo pmset -a womp 1

    info "电源管理配置完成，当前设置："
    pmset -g | grep -E "sleep|disksleep|autorestart|womp" | head -4
}

# ── 2. Tailscale ──
setup_tailscale() {
    section "2. Tailscale 配置"

    if ! command -v tailscale &>/dev/null; then
        echo "Tailscale 未安装。请选择安装方式："
        echo "  1) brew install --cask tailscale"
        echo "  2) 从 Mac App Store 安装"
        echo "  3) 下载独立包: https://pkgs.tailscale.com/stable/"
        echo ""
        read -rp "选择 [1/2/3] 或按 Enter 跳过: " choice
        case "$choice" in
            1) brew install --cask tailscale ;;
            2) open "macappstore://apps.apple.com/app/tailscale/id1475387142" ; echo "请在 App Store 中完成安装后重新运行此脚本" ; return ;;
            3) open "https://pkgs.tailscale.com/stable/" ; echo "请下载安装后重新运行此脚本" ; return ;;
            *) warn "跳过 Tailscale 安装" ; return ;;
        esac
    fi

    if tailscale status &>/dev/null 2>&1; then
        info "Tailscale 已连接"
        tailscale status
    else
        info "启动 Tailscale 认证..."
        tailscale up
    fi

    # 启用 Tailscale SSH
    echo ""
    read -rp "是否启用 Tailscale SSH（管理员远程管理）？[y/N] " enable_ssh
    if [[ "${enable_ssh,,}" == "y" ]]; then
        tailscale set --ssh
        info "Tailscale SSH 已启用"
    fi
}

# ── 3. NAS SSH 密钥 ──
setup_nas_ssh() {
    section "3. NAS SSH 密钥配置"

    local nas_key="$HOME/.ssh/id_nas"

    if [[ -f "$nas_key" ]]; then
        info "NAS SSH 密钥已存在: $nas_key"
        read -rp "是否重新生成？[y/N] " regen
        if [[ "${regen,,}" != "y" ]]; then
            return
        fi
    fi

    read -rp "NAS 主机名或 IP [ugreen-nas]: " nas_host
    nas_host="${nas_host:-ugreen-nas}"

    read -rp "NAS 用户名 [openclaw-agent]: " nas_user
    nas_user="${nas_user:-openclaw-agent}"

    info "生成 SSH 密钥..."
    ssh-keygen -t ed25519 -C "openclaw@mac-studio" -f "$nas_key" -N ""

    info "上传公钥到 NAS..."
    echo "请输入 NAS 上 ${nas_user} 的密码："
    ssh-copy-id -i "${nas_key}.pub" "${nas_user}@${nas_host}" || {
        warn "公钥上传失败。可稍后手动执行: ssh-copy-id -i ${nas_key}.pub ${nas_user}@${nas_host}"
        return
    }

    # 配置 SSH config
    if ! grep -q "Host ${nas_host}" "$HOME/.ssh/config" 2>/dev/null; then
        mkdir -p "$HOME/.ssh"
        cat >> "$HOME/.ssh/config" <<EOF

Host ${nas_host}
    HostName ${nas_host}
    User ${nas_user}
    IdentityFile ${nas_key}
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
        info "SSH config 已更新"
    fi

    # 测试连接
    if ssh -i "$nas_key" -o ConnectTimeout=5 "${nas_user}@${nas_host}" "echo ok" &>/dev/null 2>&1; then
        info "SSH 连接测试成功"
    else
        warn "SSH 连接测试失败，NAS 可能不在线"
    fi
}

# ── 4. NAS SMB 挂载 ──
setup_nas_mount() {
    section "4. NAS SMB 挂载配置"

    local mount_point="$HOME/mounts/nas-workspace"

    read -rp "NAS 主机名 [ugreen-nas]: " nas_host
    nas_host="${nas_host:-ugreen-nas}"

    read -rp "SMB 共享名 [openclaw-workspace]: " share_name
    share_name="${share_name:-openclaw-workspace}"

    read -rp "NAS 用户名 [openclaw-agent]: " nas_user
    nas_user="${nas_user:-openclaw-agent}"

    mkdir -p "$mount_point"
    info "挂载点已创建: $mount_point"

    # 存储密码到 Keychain
    echo ""
    echo "将 SMB 密码存入 macOS Keychain（避免明文存储）..."
    read -rsp "请输入 ${nas_user} 的 SMB 密码: " smb_password
    echo ""

    security add-internet-password -a "$nas_user" -s "$nas_host" \
        -w "$smb_password" -T /sbin/mount_smbfs -U 2>/dev/null || \
    security add-internet-password -a "$nas_user" -s "$nas_host" \
        -w "$smb_password" -T /sbin/mount_smbfs 2>/dev/null || \
        warn "Keychain 写入失败（可能已存在），请手动管理"

    # 测试挂载
    echo ""
    info "测试 SMB 挂载..."
    if mount_smbfs "//${nas_user}@${nas_host}/${share_name}" "$mount_point" 2>/dev/null; then
        info "SMB 挂载成功"
        ls "$mount_point"
        umount "$mount_point" 2>/dev/null
    else
        warn "SMB 挂载失败。可能原因: NAS 不在线、SMB 服务未启用、密码错误"
    fi

    # 创建 LaunchAgent
    echo ""
    read -rp "是否创建开机自动挂载 LaunchAgent？[y/N] " create_la
    if [[ "${create_la,,}" == "y" ]]; then
        local plist_path="$HOME/Library/LaunchAgents/com.openclaw.nas-mount.plist"
        local current_user
        current_user=$(whoami)

        cat > "$plist_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.openclaw.nas-mount</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>for i in \$(seq 1 30); do tailscale status &amp;&amp; break; sleep 2; done; mount_smbfs //${nas_user}@${nas_host}/${share_name} /Users/${current_user}/mounts/nas-workspace</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardErrorPath</key>
  <string>/tmp/nas-mount.err</string>
</dict>
</plist>
PLIST
        launchctl load "$plist_path" 2>/dev/null || true
        info "LaunchAgent 已创建: $plist_path"
    fi
}

# ── 5. OpenClaw 配置 ──
setup_openclaw() {
    section "5. OpenClaw 配置"

    if ! command -v openclaw &>/dev/null; then
        info "安装 OpenClaw..."
        brew tap openclaw/tap && brew install openclaw
    else
        info "OpenClaw 已安装: $(openclaw --version 2>/dev/null || echo '版本未知')"
    fi

    local env_file="$HOME/.openclaw/.env"
    mkdir -p "$HOME/.openclaw"

    if [[ ! -f "$env_file" ]]; then
        echo ""
        echo "配置 API 密钥（写入 $env_file）："
        read -rp "ANTHROPIC_API_KEY (sk-ant-...): " api_key
        read -rp "TELEGRAM_BOT_TOKEN (可选，按 Enter 跳过): " bot_token

        {
            echo "ANTHROPIC_API_KEY=${api_key}"
            [[ -n "$bot_token" ]] && echo "TELEGRAM_BOT_TOKEN=${bot_token}"
        } > "$env_file"
        chmod 600 "$env_file"
        info ".env 文件已创建，权限 600"
    else
        info ".env 文件已存在"
        local perms
        perms=$(stat -f %Lp "$env_file" 2>/dev/null || stat -c %a "$env_file" 2>/dev/null || echo "unknown")
        if [[ "$perms" != "600" ]]; then
            chmod 600 "$env_file"
            info "已修复 .env 权限为 600"
        fi
    fi

    # 创建脚本目录
    mkdir -p "$HOME/.openclaw/scripts"
    mkdir -p "$HOME/.openclaw/logs"

    info "运行诊断..."
    openclaw doctor || warn "openclaw doctor 报告了问题，请查看输出"
}

# ── 6. 备份 cron ──
setup_backup_cron() {
    section "6. 自动备份配置"

    read -rp "是否配置每日自动备份到 NAS？[y/N] " setup_cron
    if [[ "${setup_cron,,}" != "y" ]]; then
        warn "跳过自动备份配置"
        return
    fi

    local script_src
    script_src="$(cd "$(dirname "$0")" && pwd)/backup.sh"

    if [[ ! -f "$script_src" ]]; then
        warn "backup.sh 不在 scripts/ 目录中，跳过"
        return
    fi

    # 复制到 ~/.openclaw/scripts/
    cp "$script_src" "$HOME/.openclaw/scripts/backup.sh"
    chmod 700 "$HOME/.openclaw/scripts/backup.sh"

    # 添加 cron
    local cron_cmd="0 3 * * * $HOME/.openclaw/scripts/backup.sh >> $HOME/.openclaw/logs/backup.log 2>&1"
    if crontab -l 2>/dev/null | grep -q "backup.sh"; then
        info "备份 cron 已存在"
    else
        (crontab -l 2>/dev/null; echo "$cron_cmd") | crontab -
        info "已添加每日凌晨 3 点自动备份 cron"
    fi
}

# ── 主逻辑 ──
main() {
    echo "================================================="
    echo "  Mac Studio 24/7 服务器配置向导"
    echo "  对应指南: guide/008-remote-sandbox.md"
    echo "================================================="

    check_prerequisites

    setup_power
    setup_tailscale
    setup_nas_ssh
    setup_nas_mount
    setup_openclaw
    setup_backup_cron

    section "配置完成"
    echo ""
    info "建议下一步操作："
    echo "  1. 编辑 ~/.openclaw/openclaw.json 完善配置（参考 guide/008）"
    echo "  2. 在 Tailscale 控制台配置 ACL 规则"
    echo "  3. 运行 bash scripts/health-check.sh 验证所有配置"
    echo "  4. 运行 bash scripts/test-008.sh 执行完整测试"
}

main
