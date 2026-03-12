#!/bin/bash
# OpenClaw 密钥轮换脚本
# 用法: bash scripts/rotate-keys.sh [--check-only]
#
# 对应指南: guide/008-remote-sandbox.md 第五章
#
# 功能:
# - 备份当前 .env 密钥
# - 引导管理员更新 API Key
# - 验证新密钥格式
# - 重启 Gateway 生效
# - 提醒撤销旧密钥
#
# 建议每 30 天执行一次

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

ENV_FILE="$HOME/.openclaw/.env"
BACKUP_DIR="$HOME/.openclaw/key-history"
LOG_FILE="$HOME/.openclaw/logs/key-rotation.log"
CHECK_ONLY=false

if [[ "${1:-}" == "--check-only" ]]; then
    CHECK_ONLY=true
fi

mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

# ── 检查密钥年龄 ──
check_key_age() {
    echo "================================================="
    echo "  OpenClaw 密钥轮换检查"
    echo "================================================="
    echo ""

    if [[ ! -f "$ENV_FILE" ]]; then
        error ".env 文件不存在: $ENV_FILE"
    fi

    # 检查 .env 文件修改时间
    local mod_days
    if [[ "$(uname)" == "Darwin" ]]; then
        local mod_ts
        mod_ts=$(stat -f %m "$ENV_FILE" 2>/dev/null || echo "0")
        local now_ts
        now_ts=$(date +%s)
        mod_days=$(( (now_ts - mod_ts) / 86400 ))
    else
        mod_days=$(( ($(date +%s) - $(stat -c %Y "$ENV_FILE" 2>/dev/null || echo "0")) / 86400 ))
    fi

    echo "【密钥状态】"
    echo "  .env 文件: $ENV_FILE"
    echo "  上次修改: ${mod_days} 天前"
    echo ""

    if [[ "$mod_days" -gt 90 ]]; then
        echo -e "  ${RED}✗${NC} 密钥已超过 90 天未轮换（高风险）"
    elif [[ "$mod_days" -gt 30 ]]; then
        echo -e "  ${YELLOW}!${NC} 密钥已超过 30 天未轮换（建议轮换）"
    else
        echo -e "  ${GREEN}✓${NC} 密钥在 30 天内有更新"
    fi

    # 检查各密钥是否存在
    echo ""
    echo "【已配置的密钥】"

    while IFS='=' read -r key value; do
        # 跳过空行和注释
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        # 脱敏显示
        local masked
        if [[ ${#value} -gt 8 ]]; then
            masked="${value:0:4}...${value: -4}"
        else
            masked="****"
        fi
        echo "  $key = $masked"
    done < "$ENV_FILE"

    # 检查备份历史
    echo ""
    local backup_count
    backup_count=$(find "$BACKUP_DIR" -name ".env.*" 2>/dev/null | wc -l || echo "0")
    echo "【轮换历史】"
    echo "  备份数量: ${backup_count}"
    if [[ "$backup_count" -gt 0 ]]; then
        echo "  最近备份:"
        find "$BACKUP_DIR" -name ".env.*" -print 2>/dev/null | sort | tail -3 | while read -r f; do
            echo "    $(basename "$f")"
        done
    fi
}

# ── 执行轮换 ──
rotate_keys() {
    echo ""
    echo "================================================="
    echo "  执行密钥轮换"
    echo "================================================="
    echo ""

    # 1. 备份当前 .env
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    cp "$ENV_FILE" "$BACKUP_DIR/.env.${timestamp}"
    chmod 600 "$BACKUP_DIR/.env.${timestamp}"
    info "当前 .env 已备份: $BACKUP_DIR/.env.${timestamp}"

    # 2. 逐项引导更新
    echo ""
    echo "请按提示更新密钥。直接按 Enter 跳过不更新的项。"
    echo ""

    local updated=false
    local tmp_env
    tmp_env=$(mktemp)
    cp "$ENV_FILE" "$tmp_env"

    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue

        local hint=""
        case "$key" in
            ANTHROPIC_API_KEY)
                hint="(在 console.anthropic.com → API Keys → Create Key 生成)" ;;
            TELEGRAM_BOT_TOKEN)
                hint="(在 Telegram @BotFather → /token 重新生成)" ;;
            GATEWAY_PASSWORD)
                hint="(设置一个新的强密码)" ;;
            *)
                hint="" ;;
        esac

        echo -e "${CYAN}${key}${NC} ${hint}"
        read -rp "  新值 (Enter 跳过): " new_value

        if [[ -n "$new_value" ]]; then
            # 在临时文件中替换
            if grep -q "^${key}=" "$tmp_env"; then
                sed -i.bak "s|^${key}=.*|${key}=${new_value}|" "$tmp_env"
                rm -f "${tmp_env}.bak"
            else
                echo "${key}=${new_value}" >> "$tmp_env"
            fi
            updated=true
            info "${key} 已更新"
        else
            warn "${key} 保持不变"
        fi
    done < "$ENV_FILE"

    if [[ "$updated" != "true" ]]; then
        warn "未更新任何密钥，退出"
        rm -f "$tmp_env"
        return
    fi

    # 3. 格式验证
    echo ""
    echo "【验证新密钥格式】"

    local has_error=false
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        case "$key" in
            ANTHROPIC_API_KEY)
                if [[ "$value" =~ ^sk-ant- ]]; then
                    echo -e "  ${GREEN}✓${NC} $key 格式正确"
                else
                    echo -e "  ${RED}✗${NC} $key 应以 sk-ant- 开头"
                    has_error=true
                fi ;;
            TELEGRAM_BOT_TOKEN)
                if [[ "$value" =~ ^[0-9]+: ]]; then
                    echo -e "  ${GREEN}✓${NC} $key 格式正确"
                else
                    echo -e "  ${RED}✗${NC} $key 格式异常（应为 数字:字符串）"
                    has_error=true
                fi ;;
            *)
                echo -e "  ${GREEN}✓${NC} $key（无格式要求）" ;;
        esac
    done < "$tmp_env"

    if [[ "$has_error" == "true" ]]; then
        echo ""
        read -rp "存在格式问题，是否仍然继续？[y/N] " force
        if [[ "${force,,}" != "y" ]]; then
            warn "已取消，.env 未变更"
            rm -f "$tmp_env"
            return
        fi
    fi

    # 4. 写入并重启
    cp "$tmp_env" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    rm -f "$tmp_env"

    echo ""
    info ".env 已更新"

    read -rp "是否重启 OpenClaw Gateway 使新密钥生效？[Y/n] " restart
    if [[ "${restart,,}" != "n" ]]; then
        launchctl stop com.openclaw.gateway 2>/dev/null || true
        sleep 2
        launchctl start com.openclaw.gateway 2>/dev/null || {
            warn "launchd 重启失败，请手动执行: openclaw stop && openclaw start"
        }
        info "Gateway 已重启"
    fi

    # 5. 记录日志
    echo "[$(date -Iseconds)] 密钥轮换完成" >> "$LOG_FILE"

    # 6. 提醒撤销旧密钥
    echo ""
    echo "================================================="
    echo -e "  ${YELLOW}重要提醒：请立即撤销旧密钥${NC}"
    echo "================================================="
    echo ""
    echo "  1. Anthropic: console.anthropic.com → API Keys → 删除旧 Key"
    echo "  2. Telegram:  @BotFather → /revoke（如已更换 Token）"
    echo "  3. 旧 .env 备份保留在: $BACKUP_DIR"
    echo "     30 天后可手动清理旧备份"
}

# ── 主逻辑 ──
check_key_age

if [[ "$CHECK_ONLY" == "true" ]]; then
    exit 0
fi

echo ""
read -rp "是否执行密钥轮换？[y/N] " do_rotate
if [[ "${do_rotate,,}" == "y" ]]; then
    rotate_keys
else
    info "已跳过轮换"
fi
