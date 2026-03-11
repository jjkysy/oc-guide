#!/bin/bash
# OpenClaw 配置备份脚本
# 用法: bash scripts/backup.sh [备份目录]
#
# 备份 ~/.openclaw/ 中的配置、记忆和代理文件
# 默认备份到 ~/openclaw-backups/

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

OPENCLAW_DIR="$HOME/.openclaw"
BACKUP_BASE="${1:-$HOME/openclaw-backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_BASE/openclaw-backup-${TIMESTAMP}.tar.gz"

main() {
    echo "================================================="
    echo "  OpenClaw 配置备份"
    echo "================================================="
    echo ""

    # 检查源目录
    if [[ ! -d "$OPENCLAW_DIR" ]]; then
        error "$OPENCLAW_DIR 不存在，无需备份"
    fi

    # 创建备份目录
    mkdir -p "$BACKUP_BASE"

    # 统计大小
    local size
    size=$(du -sh "$OPENCLAW_DIR" | cut -f1)
    info "源目录: $OPENCLAW_DIR ($size)"
    info "备份到: $BACKUP_FILE"

    # 执行备份（排除日志和临时文件）
    tar -czf "$BACKUP_FILE" \
        --exclude='*.log' \
        --exclude='sessions/*' \
        --exclude='logs/*' \
        -C "$HOME" .openclaw/

    local backup_size
    backup_size=$(du -sh "$BACKUP_FILE" | cut -f1)
    info "备份完成！文件大小: $backup_size"

    # 清理旧备份（保留最近 10 个）
    local count
    count=$(ls -1 "$BACKUP_BASE"/openclaw-backup-*.tar.gz 2>/dev/null | wc -l)
    if [[ "$count" -gt 10 ]]; then
        info "清理旧备份（保留最近 10 个）..."
        ls -1t "$BACKUP_BASE"/openclaw-backup-*.tar.gz | tail -n +11 | xargs rm -f
        info "已清理 $((count - 10)) 个旧备份"
    fi

    echo ""
    info "恢复命令: tar -xzf $BACKUP_FILE -C \$HOME"
}

main
