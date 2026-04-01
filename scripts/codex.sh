#!/bin/bash
# Codex (ChatGPT Plus) 用量查询模块

set -e

# 加载环境变量
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# 检查必需的环境变量
if [ -z "$CODEX_BEARER_TOKEN" ] || [ -z "$CODEX_ACCOUNT_ID" ]; then
    echo "Codex|N/A|N/A|N/A|N/A|N/A|❌ 缺少配置"
    exit 1
fi

# 调用 API
RESPONSE=$(curl -s -X GET \
    "https://chatgpt.com/backend-api/wham/usage" \
    -H "Authorization: Bearer ${CODEX_BEARER_TOKEN}" \
    -H "Account-Id: ${CODEX_ACCOUNT_ID}")

# 解析 JSON
if ! command -v jq &> /dev/null; then
    echo "Codex|N/A|N/A|N/A|N/A|N/A|❌ 需要安装 jq"
    exit 1
fi

# 解析 - API 返回的是 rate_limit 结构，不是 subscription_usage
PRIMARY_PCT=$(echo "$RESPONSE" | jq -r '.rate_limit.primary_window.used_percent // 0')
PRIMARY_LEFT=$(echo "$RESPONSE" | jq -r '.rate_limit.primary_window.reset_after_seconds // 0')
SECONDARY_PCT=$(echo "$RESPONSE" | jq -r '.rate_limit.secondary_window.used_percent // 0')
SECONDARY_LEFT=$(echo "$RESPONSE" | jq -r '.rate_limit.secondary_window.reset_after_seconds // 0')

if [ "$PRIMARY_PCT" = "null" ] || [ "$PRIMARY_PCT" = "null" ]; then
    echo "Codex|N/A|N/A|N/A|N/A|N/A|❌ 解析失败"
    exit 1
fi

# Primary window: 5小时窗口 (18000s)
# Secondary window: 7天窗口 (604800s)
# used_percent 已经是百分比数字 (0-100)

P5H_LEFT=$(awk "BEGIN {printf \"%.0f\", 100 - $PRIMARY_PCT}")
P7D_LEFT=$(awk "BEGIN {printf \"%.0f\", 100 - $SECONDARY_PCT}")

# 计算刷新时间
format_duration() {
    local seconds=$1
    if [ "$seconds" -le 0 ]; then
        echo "即将刷新"
        return
    fi
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local mins=$(((seconds % 3600) / 60))

    if [ "$days" -gt 0 ]; then
        echo "${days}d ${hours}h 后刷新"
    elif [ "$hours" -gt 0 ]; then
        echo "${hours}h ${mins}m 后刷新"
    else
        echo "${mins}m 后刷新"
    fi
}

RESET_5H=$(format_duration $PRIMARY_LEFT)
RESET_7D=$(format_duration $((SECONDARY_LEFT)))

# 状态判断
if [ "$SECONDARY_PCT" -lt 60 ]; then
    STATUS="✅"
elif [ "$SECONDARY_PCT" -lt 85 ]; then
    STATUS="⚠️"
else
    STATUS="🔴"
fi

# 输出统一格式：显示 7d 用量和 5h 用量
echo "Codex-7d|${SECONDARY_PCT}|100|${SECONDARY_PCT}%|${P7D_LEFT}|${RESET_7D}|${STATUS}"
echo "Codex-5h|${PRIMARY_PCT}|100|${PRIMARY_PCT}%|${P5H_LEFT}|${RESET_5H}|${STATUS}"
