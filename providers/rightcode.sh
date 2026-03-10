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
REMAINING=$(echo "$SUMMARY" | jq -r '.current_remaining')
HAS_RESET=$(echo "$SUMMARY" | jq -r '.has_reset')
HAS_NOT_RESET=$(echo "$SUMMARY" | jq -r '.has_not_reset')

# 计算百分比
PERCENT=$(awk "BEGIN {if ($TOTAL > 0) printf \"%.0f\", ($USED/$TOTAL)*100; else print 0}")

# RightCode 每天北京时间 12:00 重置
RESET_TIME="12:00"

# 状态判断图标
if [ "$PERCENT" -lt 60 ]; then
    STATUS="✅"
elif [ "$PERCENT" -lt 85 ]; then
    STATUS="⚠️"
else
    STATUS="🔴"
fi

# 详细重置状态标识
RESET_INDICATOR=""
if [ "$HAS_RESET" == "true" ] && [ "$HAS_NOT_RESET" == "true" ]; then
    RESET_INDICATOR="🔄⏳"
elif [ "$HAS_RESET" == "true" ]; then
    RESET_INDICATOR="🔄"
elif [ "$HAS_NOT_RESET" == "true" ]; then
    RESET_INDICATOR="⏳"
fi

# 输出统一格式 (剩余额度显示当前真实的 remaining，移除到期时间)
echo "RightCode|$USED|$TOTAL|$PERCENT%|$REMAINING|$RESET_INDICATOR|$STATUS"
