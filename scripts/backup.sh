#!/bin/bash
# OpenClaw 配置备份脚本
# 用法: bash scripts/backup.sh [--local [目录]] [--nas]
#
# 备份 ~/.openclaw/ 中的配置、记忆和代理文件
#   --local [目录]  备份到本地（默认 ~/openclaw-backups/）
#   --nas           通过 SSH 备份到 NAS 隔离备份区
#   无参数          默认 --local
#
# 对应指南: guide/008-remote-sandbox.md 第六章

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

OPENCLAW_DIR="$HOME/.openclaw"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MODE="local"
LOCAL_BACKUP_BASE="$HOME/openclaw-backups"

# NAS 配置（对应 008 架构）
NAS_HOST="ugreen-nas"
NAS_SSH_KEY="$HOME/.ssh/id_nas"
NAS_BACKUP_DIR="/volume1/openclaw-backup/snapshots"
NAS_USER="openclaw-agent"

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local)
            MODE="local"
            if [[ -n "${2:-}" && ! "$2" =~ ^-- ]]; then
                LOCAL_BACKUP_BASE="$2"
                shift
            fi
            ;;
        --nas)
            MODE="nas"
            ;;
        *)
            # 兼容旧版：裸参数当作本地备份目录
            LOCAL_BACKUP_BASE="$1"
            MODE="local"
            ;;
    esac
    shift
done

# 检查源目录
if [[ ! -d "$OPENCLAW_DIR" ]]; then
    error "$OPENCLAW_DIR 不存在，无需备份"
fi

# 创建临时备份包
create_backup_archive() {
    local archive="$1"

    local size
    size=$(du -sh "$OPENCLAW_DIR" | cut -f1)
    info "源目录: $OPENCLAW_DIR ($size)"

    tar -czf "$archive" \
        --exclude='*.log' \
        --exclude='sessions/*' \
        --exclude='logs/*' \
        --exclude='key-history/*' \
        -C "$HOME" .openclaw/

    local archive_size
    archive_size=$(du -sh "$archive" | cut -f1)
    info "备份包大小: $archive_size"
}

# 本地备份
backup_local() {
    echo "================================================="
    echo "  OpenClaw 本地备份"
    echo "================================================="
    echo ""

    mkdir -p "$LOCAL_BACKUP_BASE"

    local backup_file="$LOCAL_BACKUP_BASE/openclaw-backup-${TIMESTAMP}.tar.gz"

    create_backup_archive "$backup_file"
    info "已备份到: $backup_file"

    # 清理旧备份（保留最近 10 个）
    local count
    count=$(find "$LOCAL_BACKUP_BASE" -name "openclaw-backup-*.tar.gz" -maxdepth 1 2>/dev/null | wc -l)
    if [[ "$count" -gt 10 ]]; then
        info "清理旧备份（保留最近 10 个）..."
        find "$LOCAL_BACKUP_BASE" -name "openclaw-backup-*.tar.gz" -maxdepth 1 -print0 2>/dev/null \
            | xargs -0 ls -1t \
            | tail -n +11 \
            | xargs rm -f
        info "已清理 $((count - 10)) 个旧备份"
    fi

    echo ""
    info "恢复命令: tar -xzf $backup_file -C \$HOME"
}

# NAS 远程备份
backup_nas() {
    echo "================================================="
    echo "  OpenClaw NAS 远程备份"
    echo "  目标: ${NAS_USER}@${NAS_HOST}:${NAS_BACKUP_DIR}"
    echo "================================================="
    echo ""

    # 检查 SSH 密钥
    if [[ ! -f "$NAS_SSH_KEY" ]]; then
        error "NAS SSH 密钥不存在: $NAS_SSH_KEY"
    fi

    # 检查 NAS 连通性
    if ! ssh -i "$NAS_SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes \
          "${NAS_USER}@${NAS_HOST}" "echo ok" &>/dev/null 2>&1; then
        error "无法连接到 NAS ($NAS_HOST)。请检查: Tailscale 连接、SSH 密钥、NAS 状态"
    fi
    info "NAS 连接正常"

    # 在 NAS 上创建备份目录
    ssh -i "$NAS_SSH_KEY" "${NAS_USER}@${NAS_HOST}" "mkdir -p ${NAS_BACKUP_DIR}" 2>/dev/null || {
        warn "在 NAS 上创建目录失败，尝试使用管理员 SSH..."
        # 如果 openclaw-agent 没有权限创建备份目录，这是预期的（见 008 第三章）
        # 备份目录应由管理员通过 root SSH 预先创建
        error "备份目录不存在且无法创建: $NAS_BACKUP_DIR。请管理员先在 NAS 上创建此目录并授权。"
    }

    # 创建临时备份包
    local tmp_archive="/tmp/openclaw-backup-${TIMESTAMP}.tar.gz"
    create_backup_archive "$tmp_archive"

    # 传输到 NAS
    info "传输到 NAS..."
    scp -i "$NAS_SSH_KEY" "$tmp_archive" "${NAS_USER}@${NAS_HOST}:${NAS_BACKUP_DIR}/" || {
        rm -f "$tmp_archive"
        error "传输失败"
    }
    rm -f "$tmp_archive"
    info "已备份到 NAS: ${NAS_BACKUP_DIR}/openclaw-backup-${TIMESTAMP}.tar.gz"

    # 清理 NAS 上的旧备份（保留 30 天）
    info "清理 NAS 上 30 天前的备份..."
    ssh -i "$NAS_SSH_KEY" "${NAS_USER}@${NAS_HOST}" \
        "find ${NAS_BACKUP_DIR} -name 'openclaw-backup-*.tar.gz' -mtime +30 -delete" 2>/dev/null || \
        warn "清理旧备份失败（可能无权限）"

    echo ""
    info "恢复命令:"
    echo "  scp -i $NAS_SSH_KEY ${NAS_USER}@${NAS_HOST}:${NAS_BACKUP_DIR}/openclaw-backup-${TIMESTAMP}.tar.gz /tmp/"
    echo "  tar -xzf /tmp/openclaw-backup-${TIMESTAMP}.tar.gz -C \$HOME"
}

# 主逻辑
case "$MODE" in
    local) backup_local ;;
    nas)   backup_nas ;;
    *)     error "未知模式: $MODE" ;;
esac
