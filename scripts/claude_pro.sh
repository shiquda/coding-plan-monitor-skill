#!/bin/bash
# Claude Pro OAuth 用量查询模块

set -e

# 加载环境变量
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# 检查必需的环境变量
if [ -z "$CLAUDE_PRO_OAUTH_TOKEN" ]; then
    echo "Claude Pro|N/A|N/A|N/A|N/A|N/A|❌ 缺少配置"
    exit 1
fi

# 调用内部 OAuth Usage API
RESPONSE=$(curl -s "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer ${CLAUDE_PRO_OAUTH_TOKEN}" \
    -H "User-Agent: claude-code/2.1.59" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Accept: application/json")

# 检查返回是否包含有效数据
if ! echo "$RESPONSE" | grep -q "five_hour"; then
    echo "Claude Pro|N/A|N/A|N/A|N/A|N/A|❌ Token无效或接口不可访问"
    exit 1
fi

# 解析 JSON（需要 jq）
if ! command -v jq &> /dev/null; then
    echo "Claude Pro|N/A|N/A|N/A|N/A|N/A|❌ 需要安装 jq"
    exit 1
fi

# 提取 5h 和 7d 数据
FIVE_HOUR_PCT=$(echo "$RESPONSE" | jq -r '.five_hour.utilization // 0')
SEVEN_DAY_PCT=$(echo "$RESPONSE" | jq -r '.seven_day.utilization // 0')
RESETS_AT_5H=$(echo "$RESPONSE" | jq -r '.five_hour.resets_at // empty')
RESETS_AT_7D=$(echo "$RESPONSE" | jq -r '.seven_day.resets_at // empty')

# 转换为北京时间并计算距离重置的时长
format_reset() {
    local utc_time=$1
    local reset_ts=$(date -d "$utc_time" +%s 2>/dev/null) || return
    local now_ts=$(date -u +%s)
    local diff=$((reset_ts - now_ts))

    if [ "$diff" -le 0 ]; then
        echo "即将刷新"
        return
    fi

    local hours=$((diff / 3600))
    local minutes=$(((diff % 3600) / 60))

    if [ "$hours" -gt 24 ]; then
        local days=$((hours / 24))
        local remaining_hours=$((hours % 24))
        echo "${days}d ${remaining_hours}h"
    elif [ "$hours" -gt 0 ]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

RESET_5H=$(format_reset "$RESETS_AT_5H")
RESET_7D=$(format_reset "$RESETS_AT_7D")

# ========== 7天窗口 ==========
PERCENT_7D=${SEVEN_DAY_PCT%.*}
USED_7D=$((PERCENT_7D * 100 / 100))
TOTAL_7D=100
REMAINING_7D=$((100 - PERCENT_7D))

if [ "$PERCENT_7D" -lt 60 ]; then
    STATUS_7D="✅"
elif [ "$PERCENT_7D" -lt 85 ]; then
    STATUS_7D="⚠️"
else
    STATUS_7D="🔴"
fi

# ========== 5小时窗口 ==========
PERCENT_5H=${FIVE_HOUR_PCT%.*}
REMAINING_5H=$((100 - PERCENT_5H))

if [ "$PERCENT_5H" -lt 60 ]; then
    STATUS_5H="✅"
elif [ "$PERCENT_5H" -lt 85 ]; then
    STATUS_5H="⚠️"
else
    STATUS_5H="🔴"
fi

# 输出两条记录（7d 和 5h）
echo "Claude Pro-7d|${PERCENT_7D}|${TOTAL_7D}|${PERCENT_7D}%|${REMAINING_7D}|${RESET_7D}|${STATUS_7D}"
echo "Claude Pro-5h|${PERCENT_5H}|100|${PERCENT_5H}%|${REMAINING_5H}|${RESET_5H}|${STATUS_5H}"
