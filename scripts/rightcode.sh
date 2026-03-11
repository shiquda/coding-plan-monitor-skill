#!/bin/bash
# RightCode 用量查询模块 (潜在双倍额度计算逻辑)

set -e

# 加载环境变量
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# 检查必需的环境变量
if [ -z "$RIGHTCODE_TOKEN" ]; then
    echo "RightCode|N/A|N/A|N/A|N/A|N/A|❌ 缺少配置"
    exit 1
fi

# 调用 API
RESPONSE=$(curl -s -X GET \
    "https://right.codes/subscriptions/list" \
    -H "Authorization: Bearer ${RIGHTCODE_TOKEN}")

# 解析 JSON
if ! command -v jq &> /dev/null; then
    echo "RightCode|N/A|N/A|N/A|N/A|N/A|❌ 需要安装 jq"
    exit 1
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 计算逻辑说明：
# 1. 理论总额 (Theoretical Total) = sum(total_quota * 2) 假设每天重置一次，总潜在额度是两天的量
# 2. 已用额度 (Simulated Used):
#    - 如果 reset_today == true (已重置): 说明今天的新额度已经开始用了，已用 = (total_quota) + (total_quota - remaining_quota)
#    - 如果 reset_today == false (未重置): 说明还在用旧额度，已用 = (total_quota - remaining_quota)
SUMMARY=$(echo "$RESPONSE" | jq --arg now "$NOW" '
  .subscriptions 
  | map(select(.expired_at >= $now))
  | {
      theoretical_total: (map(.total_quota * 2) | add // 0),
      simulated_used: (map(if .reset_today == true then (.total_quota + (.total_quota - .remaining_quota)) else (.total_quota - .remaining_quota) end) | add // 0),
      current_remaining: (map(.remaining_quota) | add // 0),
      expired_at: (map(.expired_at) | min // "未知"),
      has_reset: (any(.reset_today == true)),
      has_not_reset: (any(.reset_today == false))
    }
')

TOTAL=$(echo "$SUMMARY" | jq -r '.theoretical_total')
USED=$(echo "$SUMMARY" | jq -r '.simulated_used')
# 统一口径：既然 TOTAL/USED 用的是“潜在双倍额度”视角，REMAINING 也必须按同口径计算
REMAINING=$(awk "BEGIN {printf \"%.1f\", $TOTAL - $USED}")
HAS_RESET=$(echo "$SUMMARY" | jq -r '.has_reset')
HAS_NOT_RESET=$(echo "$SUMMARY" | jq -r '.has_not_reset')

# 计算百分比与清爽显示
PERCENT=$(awk "BEGIN {if ($TOTAL > 0) printf \"%.0f\", ($USED/$TOTAL)*100; else print 0}")
USED=$(awk "BEGIN {printf \"%.1f\", $USED}")
TOTAL=$(awk "BEGIN {printf \"%.2f\", $TOTAL}")

# RightCode 每天北京时间 24:00 重置，统一显示剩余时长
format_duration() {
    local seconds=$1
    if [ "$seconds" -le 0 ] 2>/dev/null; then
        echo "刚刚刷新"
        return
    fi
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local minutes=$(((seconds % 3600) / 60))

    if [ "$days" -gt 0 ]; then
        if [ "$hours" -gt 0 ]; then
            echo "${days}d ${hours}h 后刷新"
        else
            echo "${days}d 后刷新"
        fi
    elif [ "$hours" -gt 0 ]; then
        if [ "$minutes" -gt 0 ]; then
            echo "${hours}h ${minutes}m 后刷新"
        else
            echo "${hours}h 后刷新"
        fi
    else
        echo "${minutes}m 后刷新"
    fi
}

NOW_TS=$(TZ=Asia/Shanghai date +%s)
TOMORROW_MIDNIGHT_TS=$(TZ=Asia/Shanghai date -d "tomorrow 00:00" +%s)
RESET_TIME=$(format_duration $((TOMORROW_MIDNIGHT_TS - NOW_TS)))

# 状态判断图标
if [ "$PERCENT" -lt 60 ]; then
    STATUS="✅"
elif [ "$PERCENT" -lt 85 ]; then
    STATUS="⚠️"
else
    STATUS="🔴"
fi

# 输出统一格式 (统一显示多久后刷新)
echo "RightCode|$USED|$TOTAL|$PERCENT%|$REMAINING|$RESET_TIME|$STATUS"
