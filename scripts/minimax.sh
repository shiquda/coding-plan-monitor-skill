#!/bin/bash
# MiniMax Coding Plan 用量查询模块

set -e

# 加载环境变量
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# 检查必需的环境变量
if [ -z "$MINIMAX_CODING_API_KEY" ]; then
    echo "MiniMax|N/A|N/A|N/A|N/A|N/A|❌ 缺少配置"
    exit 1
fi

# 调用 API（国内端点）
RESPONSE=$(curl -s -X GET \
    "https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains" \
    -H "Authorization: Bearer ${MINIMAX_CODING_API_KEY}")

# 解析 JSON (需要 jq)
if ! command -v jq &> /dev/null; then
    echo "MiniMax|N/A|N/A|N/A|N/A|N/A|❌ 需要安装 jq"
    exit 1
fi

# 提取第一个模型的数据（所有模型共享额度）
# 注意：current_interval_usage_count 实际是"剩余"，不是"已用"
REMAINING=$(echo "$RESPONSE" | jq -r '.model_remains[0].current_interval_usage_count // 0')
TOTAL=$(echo "$RESPONSE" | jq -r '.model_remains[0].current_interval_total_count // 600')
REMAINS_MS=$(echo "$RESPONSE" | jq -r '.model_remains[0].remains_time // 0')

# 计算已用
USED=$((TOTAL - REMAINING))

# 计算百分比
PERCENT=$(awk "BEGIN {printf \"%.0f\", ($USED/$TOTAL)*100}")

# 转换剩余时间为可读格式
HOURS=$((REMAINS_MS / 3600000))
MINUTES=$(((REMAINS_MS % 3600000) / 60000))
RESET_TIME="${HOURS}h${MINUTES}m"

# 状态判断
if [ "$PERCENT" -lt 60 ]; then
    STATUS="✅"
elif [ "$PERCENT" -lt 85 ]; then
    STATUS="⚠️"
else
    STATUS="🔴"
fi

# 输出统一格式
echo "MiniMax|$USED|$TOTAL|$PERCENT%|$REMAINING|$RESET_TIME|$STATUS"
